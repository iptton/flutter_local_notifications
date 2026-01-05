/*
 * Copyright (c) 2024. flutter_local_notifications_ohos
 * Licensed under BSD-3-Clause License
 */

import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG = 'FlutterLocalNotificationsPlugin';
const CHANNEL_NAME = 'dexterous.com/flutter/local_notifications';

// RepeatInterval enum values matching Dart side
enum RepeatInterval {
  everyMinute = 0,
  hourly = 1,
  daily = 2,
  weekly = 3,
}

// Notification content type enum
enum ContentType {
  basic = 0,
  longText = 1,
  multiLine = 2,
  picture = 3,
}

// Slot type enum
enum SlotType {
  unknown = 0,
  socialCommunication = 1,
  serviceInformation = 2,
  contentInformation = 3,
  liveView = 4,
  customerService = 5,
  other = 6,
}

interface PendingNotification {
  id: number;
  title: string | null;
  body: string | null;
  payload: string | null;
  scheduledTime: number;
  repeatInterval?: number;
}

export default class FlutterLocalNotificationsPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private pendingNotifications: Map<number, PendingNotification> = new Map();
  private launchNotification: object | null = null;

  getUniqueClassName(): string {
    return 'FlutterLocalNotificationsPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler({
      onMethodCall: this.onMethodCall.bind(this)
    });
    this.context = binding.getApplicationContext() as common.UIAbilityContext;
    console.info(TAG, 'Plugin attached to engine');
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.context = null;
    console.info(TAG, 'Plugin detached from engine');
  }

  private async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case 'initialize':
          await this.initialize(call, result);
          break;
        case 'show':
          await this.show(call, result);
          break;
        case 'zonedSchedule':
          await this.zonedSchedule(call, result);
          break;
        case 'periodicallyShow':
          await this.periodicallyShow(call, result);
          break;
        case 'periodicallyShowWithDuration':
          await this.periodicallyShowWithDuration(call, result);
          break;
        case 'cancel':
          await this.cancel(call, result);
          break;
        case 'cancelAll':
          await this.cancelAll(result);
          break;
        case 'cancelAllPendingNotifications':
          await this.cancelAllPendingNotifications(result);
          break;
        case 'pendingNotificationRequests':
          await this.getPendingNotificationRequests(result);
          break;
        case 'getActiveNotifications':
          await this.getActiveNotifications(result);
          break;
        case 'getNotificationAppLaunchDetails':
          this.getNotificationAppLaunchDetails(result);
          break;
        case 'requestPermission':
          await this.requestPermission(result);
          break;
        case 'isNotificationEnabled':
          await this.isNotificationEnabled(result);
          break;
        default:
          result.notImplemented();
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Error handling method ${call.method}: ${err.message}`);
      result.error('PLUGIN_ERROR', err.message, null);
    }
  }

  private async initialize(call: MethodCall, result: MethodResult): Promise<void> {
    const args = call.args as Record<string, ESObject>;
    const requestPermission = args['requestPermissionOnInit'] as boolean ?? true;

    if (requestPermission) {
      try {
        const isEnabled = await notificationManager.isNotificationEnabled();
        if (!isEnabled) {
          await notificationManager.requestEnableNotification(this.context!);
        }
      } catch (error) {
        const err = error as BusinessError;
        console.warn(TAG, `Permission request failed: ${err.message}`);
      }
    }

    result.success(true);
  }

  private async show(call: MethodCall, result: MethodResult): Promise<void> {
    const args = call.args as Record<string, ESObject>;
    const id = args['id'] as number;
    const title = args['title'] as string ?? '';
    const body = args['body'] as string ?? '';
    const payload = args['payload'] as string | null;

    const notificationRequest = this.buildNotificationRequest(id, title, body, args);

    try {
      await notificationManager.publish(notificationRequest);
      console.info(TAG, `Notification ${id} published successfully`);
      result.success(null);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to publish notification: ${err.message}`);
      result.error('NOTIFICATION_ERROR', err.message, null);
    }
  }

  private buildNotificationRequest(
    id: number,
    title: string,
    body: string,
    args: Record<string, ESObject>
  ): notificationManager.NotificationRequest {
    const contentType = args['contentType'] as number ?? ContentType.basic;
    const autoCancel = args['autoCancel'] as boolean ?? true;
    const badgeNumber = args['badgeNumber'] as number | undefined;
    const groupName = args['groupName'] as string | undefined;

    let notificationContent: notificationManager.NotificationContent;

    switch (contentType) {
      case ContentType.longText:
        notificationContent = {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
          longText: {
            title: title,
            text: body,
            additionalText: args['additionalText'] as string ?? '',
            longText: args['longText'] as string ?? body,
            briefText: args['briefText'] as string ?? '',
            expandedTitle: args['expandedTitle'] as string ?? title,
          }
        };
        break;

      case ContentType.multiLine:
        const lines = args['lines'] as string[] ?? [];
        notificationContent = {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_MULTILINE,
          multiLine: {
            title: title,
            text: body,
            additionalText: args['additionalText'] as string ?? '',
            briefText: args['briefText'] as string ?? '',
            longTitle: args['expandedTitle'] as string ?? title,
            lines: lines,
          }
        };
        break;

      case ContentType.picture:
        // Note: Picture notifications require a PixelMap, which needs special handling
        // For now, fallback to basic notification
        notificationContent = {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: body,
            additionalText: args['additionalText'] as string ?? '',
          }
        };
        break;

      case ContentType.basic:
      default:
        notificationContent = {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: body,
            additionalText: args['additionalText'] as string ?? '',
          }
        };
        break;
    }

    const request: notificationManager.NotificationRequest = {
      id: id,
      content: notificationContent,
      notificationSlotType: this.mapSlotType(args['slotType'] as number ?? SlotType.serviceInformation),
    };

    if (autoCancel !== undefined) {
      request.tapDismissed = autoCancel;
    }

    if (badgeNumber !== undefined) {
      request.badgeNumber = badgeNumber;
    }

    if (groupName) {
      request.groupName = groupName;
    }

    return request;
  }

  private mapSlotType(slotType: number): notificationManager.SlotType {
    switch (slotType) {
      case SlotType.socialCommunication:
        return notificationManager.SlotType.SOCIAL_COMMUNICATION;
      case SlotType.serviceInformation:
        return notificationManager.SlotType.SERVICE_INFORMATION;
      case SlotType.contentInformation:
        return notificationManager.SlotType.CONTENT_INFORMATION;
      case SlotType.liveView:
        return notificationManager.SlotType.LIVE_VIEW;
      case SlotType.customerService:
        return notificationManager.SlotType.CUSTOMER_SERVICE;
      case SlotType.other:
        return notificationManager.SlotType.OTHER_TYPES;
      default:
        return notificationManager.SlotType.SERVICE_INFORMATION;
    }
  }

  private async zonedSchedule(call: MethodCall, result: MethodResult): Promise<void> {
    const args = call.args as Record<string, ESObject>;
    const id = args['id'] as number;
    const title = args['title'] as string ?? '';
    const body = args['body'] as string ?? '';
    const scheduledDateTime = args['scheduledDateTime'] as number;
    const payload = args['payload'] as string | null;

    // Store pending notification
    this.pendingNotifications.set(id, {
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledTime: scheduledDateTime,
    });

    // Calculate delay
    const now = Date.now();
    const delay = Math.max(0, scheduledDateTime - now);

    // Use setTimeout for scheduling (in production, use reminderAgentManager for reliability)
    setTimeout(async () => {
      if (this.pendingNotifications.has(id)) {
        const notificationRequest = this.buildNotificationRequest(id, title, body, args);
        try {
          await notificationManager.publish(notificationRequest);
          this.pendingNotifications.delete(id);
          console.info(TAG, `Scheduled notification ${id} published`);
        } catch (error) {
          const err = error as BusinessError;
          console.error(TAG, `Failed to publish scheduled notification: ${err.message}`);
        }
      }
    }, delay);

    result.success(null);
  }

  private async periodicallyShow(call: MethodCall, result: MethodResult): Promise<void> {
    const args = call.args as Record<string, ESObject>;
    const id = args['id'] as number;
    const title = args['title'] as string ?? '';
    const body = args['body'] as string ?? '';
    const repeatIntervalValue = args['repeatInterval'] as number;

    let intervalMs: number;
    switch (repeatIntervalValue) {
      case RepeatInterval.everyMinute:
        intervalMs = 60 * 1000;
        break;
      case RepeatInterval.hourly:
        intervalMs = 60 * 60 * 1000;
        break;
      case RepeatInterval.daily:
        intervalMs = 24 * 60 * 60 * 1000;
        break;
      case RepeatInterval.weekly:
        intervalMs = 7 * 24 * 60 * 60 * 1000;
        break;
      default:
        intervalMs = 24 * 60 * 60 * 1000;
    }

    // Store pending notification with repeat info
    this.pendingNotifications.set(id, {
      id: id,
      title: title,
      body: body,
      payload: null,
      scheduledTime: Date.now() + intervalMs,
      repeatInterval: intervalMs,
    });

    // Show first notification immediately, then setup periodic
    const notificationRequest = this.buildNotificationRequest(id, title, body, args);
    try {
      await notificationManager.publish(notificationRequest);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to publish periodic notification: ${err.message}`);
    }

    // Setup interval (in production, use reminderAgentManager)
    this.setupPeriodicNotification(id, title, body, args, intervalMs);

    result.success(null);
  }

  private async periodicallyShowWithDuration(call: MethodCall, result: MethodResult): Promise<void> {
    const args = call.args as Record<string, ESObject>;
    const id = args['id'] as number;
    const title = args['title'] as string ?? '';
    const body = args['body'] as string ?? '';
    const intervalMs = args['repeatDurationMilliseconds'] as number;

    // Minimum interval is 1 minute
    const safeInterval = Math.max(60000, intervalMs);

    this.pendingNotifications.set(id, {
      id: id,
      title: title,
      body: body,
      payload: null,
      scheduledTime: Date.now() + safeInterval,
      repeatInterval: safeInterval,
    });

    this.setupPeriodicNotification(id, title, body, args, safeInterval);

    result.success(null);
  }

  private setupPeriodicNotification(
    id: number,
    title: string,
    body: string,
    args: Record<string, ESObject>,
    intervalMs: number
  ): void {
    const periodicTask = setInterval(async () => {
      if (!this.pendingNotifications.has(id)) {
        clearInterval(periodicTask);
        return;
      }

      const notificationRequest = this.buildNotificationRequest(id, title, body, args);
      try {
        await notificationManager.publish(notificationRequest);
        console.info(TAG, `Periodic notification ${id} published`);
      } catch (error) {
        const err = error as BusinessError;
        console.error(TAG, `Failed to publish periodic notification: ${err.message}`);
      }
    }, intervalMs);
  }

  private async cancel(call: MethodCall, result: MethodResult): Promise<void> {
    const id = call.args as number;

    this.pendingNotifications.delete(id);

    try {
      await notificationManager.cancel(id);
      console.info(TAG, `Notification ${id} cancelled`);
      result.success(null);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to cancel notification: ${err.message}`);
      result.error('CANCEL_ERROR', err.message, null);
    }
  }

  private async cancelAll(result: MethodResult): Promise<void> {
    this.pendingNotifications.clear();

    try {
      await notificationManager.cancelAll();
      console.info(TAG, 'All notifications cancelled');
      result.success(null);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to cancel all notifications: ${err.message}`);
      result.error('CANCEL_ALL_ERROR', err.message, null);
    }
  }

  private async cancelAllPendingNotifications(result: MethodResult): Promise<void> {
    this.pendingNotifications.clear();
    result.success(null);
  }

  private async getPendingNotificationRequests(result: MethodResult): Promise<void> {
    const pending: object[] = [];

    this.pendingNotifications.forEach((notification) => {
      pending.push({
        id: notification.id,
        title: notification.title,
        body: notification.body,
        payload: notification.payload,
      });
    });

    result.success(pending);
  }

  private async getActiveNotifications(result: MethodResult): Promise<void> {
    try {
      const activeNotifications = await notificationManager.getActiveNotifications();
      const notifications: object[] = activeNotifications.map((notification) => ({
        id: notification.id,
        title: notification.content?.normal?.title ?? null,
        body: notification.content?.normal?.text ?? null,
        payload: null,
      }));
      result.success(notifications);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to get active notifications: ${err.message}`);
      result.success([]);
    }
  }

  private getNotificationAppLaunchDetails(result: MethodResult): void {
    if (this.launchNotification) {
      result.success({
        didNotificationLaunchApp: true,
        notificationResponse: this.launchNotification,
      });
    } else {
      result.success({
        didNotificationLaunchApp: false,
        notificationResponse: null,
      });
    }
  }

  private async requestPermission(result: MethodResult): Promise<void> {
    try {
      await notificationManager.requestEnableNotification(this.context!);
      const isEnabled = await notificationManager.isNotificationEnabled();
      result.success(isEnabled);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to request permission: ${err.message}`);
      result.success(false);
    }
  }

  private async isNotificationEnabled(result: MethodResult): Promise<void> {
    try {
      const isEnabled = await notificationManager.isNotificationEnabled();
      result.success(isEnabled);
    } catch (error) {
      const err = error as BusinessError;
      console.error(TAG, `Failed to check notification status: ${err.message}`);
      result.success(false);
    }
  }

  // Call this method when the app is launched via a notification
  setLaunchNotification(notificationId: number, payload: string | null): void {
    this.launchNotification = {
      responseType: 0, // selectedNotification
      id: notificationId,
      actionId: null,
      input: null,
      payload: payload,
    };
  }
}
