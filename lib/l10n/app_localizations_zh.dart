// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'E-Chat';

  @override
  String get retry => '重试';

  @override
  String get ok => '好';

  @override
  String get done => '完成';

  @override
  String get back => '返回';

  @override
  String get more => '更多';

  @override
  String get close => '关闭';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '连接已断开';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String signedInAs(String name) {
    return '当前登录：$name';
  }

  @override
  String get comingSoon => '敬请期待';

  @override
  String get comingSoonMessage => '当前聊天 MVP 暂未开放此设置。';

  @override
  String get aboutLegalese => 'Agora Chat Flutter 客户端';

  @override
  String get loginTitle => '登录 Agora Chat';

  @override
  String get loginSubtitle => '使用控制台创建的用户开始一对一聊天';

  @override
  String get userIdLabel => '用户 ID';

  @override
  String get passwordLogin => '密码登录';

  @override
  String get tokenLogin => 'Token 登录';

  @override
  String get passwordLabel => '密码';

  @override
  String get tokenLabel => 'Chat Token';

  @override
  String get showPassword => '显示';

  @override
  String get hidePassword => '隐藏';

  @override
  String get loginButton => '登录';

  @override
  String get webPreviewNote =>
      'Web 界面可以预览；Agora Chat 当前通过原生 Flutter SDK 提供 Android/iOS 收发。';

  @override
  String get passwordHint => '密码登录适用于本地测试。正式环境建议由你的服务端签发 Token。';

  @override
  String get tokenHint => '请使用可信服务端签发的用户 Token。';

  @override
  String get chatsTab => '聊天';

  @override
  String get groupsTab => '群组';

  @override
  String get profileTab => '我的';

  @override
  String get moreTab => '更多';

  @override
  String get groupsTitle => '群组';

  @override
  String get searchOrAddFriend => '搜索或添加好友';

  @override
  String get addFriendOrGroup => '添加好友或创建群组';

  @override
  String get viewAction => '查看';

  @override
  String friendRequestReceived(String userId) {
    return '$userId 发来好友申请';
  }

  @override
  String groupInvitationReceived(String inviter, String group) {
    return '$inviter 邀请你加入群聊 $group';
  }

  @override
  String groupInvitationAccepted(String group) {
    return '你已加入群聊 $group';
  }

  @override
  String groupInvitationDeclined(String group) {
    return '你已拒绝加入群聊 $group';
  }

  @override
  String friendRequestAccepted(String userId) {
    return '$userId 已接受你的好友申请';
  }

  @override
  String friendRequestDeclined(String userId) {
    return '$userId 已拒绝你的好友申请';
  }

  @override
  String friendRequestAdded(String userId) {
    return '$userId 已成为联系人';
  }

  @override
  String get addFriendAction => '添加好友';

  @override
  String get createGroupAction => '创建群组';

  @override
  String get conversationsUnavailable => '会话暂时无法加载';

  @override
  String get noChats => '还没有聊天';

  @override
  String get noGroups => '还没有群组';

  @override
  String get noChatsDetail => '添加好友，或用对方的 Agora Chat 用户 ID 开始对话。';

  @override
  String get noGroupsDetail => '创建群组并邀请联系人，一起开始聊天。';

  @override
  String get startConversation => '发送一条消息，开始对话';

  @override
  String get imageMessage => '[图片]';

  @override
  String get voiceMessage => '[语音]';

  @override
  String get fileMessage => '文件';

  @override
  String get videoMessage => '视频';

  @override
  String get locationMessage => '位置';

  @override
  String get contactMessage => '联系人';

  @override
  String get customMessage => '自定义消息';

  @override
  String get systemMessage => '系统消息';

  @override
  String get unsupportedMessage => '暂不支持的消息';

  @override
  String get conversationPreviewImage => '[图片]';

  @override
  String get conversationPreviewVoice => '[语音]';

  @override
  String get conversationPreviewFile => '[文件]';

  @override
  String get conversationPreviewVideo => '[视频]';

  @override
  String get conversationPreviewLocation => '[位置]';

  @override
  String get conversationPreviewContact => '[名片]';

  @override
  String get conversationPreviewCustom => '[自定义消息]';

  @override
  String get conversationPreviewSystem => '[系统消息]';

  @override
  String get conversationPreviewUnknown => '[暂不支持的消息]';

  @override
  String get chatTitle => '聊天';

  @override
  String get conversationDetails => '会话详情';

  @override
  String get showUserId => '显示用户 ID';

  @override
  String get groupChat => '群聊';

  @override
  String get videoCall => '视频通话';

  @override
  String get voiceCall => '语音通话';

  @override
  String get messageHint => '输入消息…';

  @override
  String get addAttachment => '添加附件';

  @override
  String get sendFailedRetry => '发送失败，重试';

  @override
  String get copy => '复制';

  @override
  String get delete => '删除';

  @override
  String get recall => '撤回';

  @override
  String get quote => '引用';

  @override
  String get forward => '转发';

  @override
  String get select => '多选';

  @override
  String get cancel => '取消';

  @override
  String get deleteMessagesTitle => '删除消息？';

  @override
  String get deleteMessagesBody => '删除后只会从当前设备移除所选消息。';

  @override
  String get recallMessageTitle => '撤回这条消息？';

  @override
  String get recallMessageBody => '撤回后无法恢复。';

  @override
  String get recalledMessage => '消息已撤回';

  @override
  String get quotedMessage => '引用的消息';

  @override
  String get quotedMessageNotFound => '引用的原消息已不存在';

  @override
  String get forwardTo => '转发给';

  @override
  String get noConversations => '暂无可转发的会话';

  @override
  String get forwarded => '已转发';

  @override
  String get copied => '已复制';

  @override
  String get deleted => '已删除';

  @override
  String selectedMessages(num count) {
    return '已选择 $count 条';
  }

  @override
  String messageActionFailed(String detail) {
    return '操作失败：$detail';
  }

  @override
  String rtcComingSoon(String callType) {
    return '$callType通话将在接入 Agora RTC 后开放。';
  }

  @override
  String get rtcVideoComingSoon => '视频通话将在接入 Agora RTC 后开放。';

  @override
  String get rtcVoiceComingSoon => '语音通话将在接入 Agora RTC 后开放。';

  @override
  String get conversationDetailsUnavailable => '会话详情暂未开放';

  @override
  String userIdValue(String userId) {
    return '用户 ID：$userId';
  }

  @override
  String get contactShareUnavailable => '联系人分享暂未接入';

  @override
  String get locationUnavailable => '位置消息暂未接入';

  @override
  String get documentUnavailable => '文件消息暂未接入';

  @override
  String get camera => '拍摄';

  @override
  String get gallery => '相册';

  @override
  String get voiceRecording => '录音';

  @override
  String stopRecording(String duration) {
    return '停止 $duration';
  }

  @override
  String get contact => '联系人';

  @override
  String get location => '位置';

  @override
  String get document => '文件';

  @override
  String get contactsTitle => '联系人';

  @override
  String get contactsLoadFailed => '无法加载联系人，点击重试';

  @override
  String get noContacts => '还没有联系人';

  @override
  String get agoraChatContact => 'Agora Chat 联系人';

  @override
  String get addFriendTitle => '添加好友';

  @override
  String get findPeople => '找人';

  @override
  String get addFriendDescription => '输入 Agora Chat 用户 ID 发送好友申请。';

  @override
  String get userIdHint => 'Agora Chat 用户 ID';

  @override
  String get sendFriendRequest => '发送好友申请';

  @override
  String get agoraChatUser => 'Agora Chat 用户';

  @override
  String friendRequestSent(String name) {
    return '已向 $name 发送好友申请。';
  }

  @override
  String get searchForFriend => '搜索好友';

  @override
  String get friendRequestsTitle => '好友申请与群邀请';

  @override
  String get noPendingFriendRequests => '暂无好友申请或群聊邀请';

  @override
  String get requestUpdateFailed => '无法更新该申请，请重试。';

  @override
  String get groupInvitation => '群聊邀请';

  @override
  String get friendRequestLabel => '好友申请';

  @override
  String invitedByUser(String userId) {
    return '邀请人：$userId';
  }

  @override
  String get requestStatusAccepted => '已同意';

  @override
  String get requestStatusDeclined => '已拒绝';

  @override
  String get requestStatusAdded => '已添加';

  @override
  String get requestStatusPending => '待处理';

  @override
  String get decline => '拒绝';

  @override
  String get accept => '接受';

  @override
  String get createGroupTitle => '创建群组';

  @override
  String get groupName => '群名称';

  @override
  String get groupNameHint => '请输入群名称';

  @override
  String get members => '成员';

  @override
  String selectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已选择 $count 人',
      zero: '未选择成员',
    );
    return '$_temp0';
  }

  @override
  String get addMembersToGroup => '添加群成员';

  @override
  String get editSelectedMembers => '编辑已选成员';

  @override
  String get createGroupButton => '创建群组';

  @override
  String get addMembersTitle => '添加群成员';

  @override
  String get searchContacts => '搜索联系人';

  @override
  String get noContactsAddFriend => '还没有联系人，请先添加好友。';

  @override
  String get profileTitle => '我的';

  @override
  String get agoraChatAccount => 'Agora Chat 账号';

  @override
  String get userIdTitle => '用户 ID';

  @override
  String get userIdSubtitle => '你的 Agora Chat 标识';

  @override
  String get accountStatus => '账号状态';

  @override
  String get signOut => '退出登录';

  @override
  String get moreTitle => '更多';

  @override
  String get privacySecurity => '隐私与安全';

  @override
  String get storage => '存储';

  @override
  String get networkHistory => '显示网络聊天记录';

  @override
  String get networkHistorySubtitle => '关闭后只显示本地缓存的历史消息';

  @override
  String get helpFeedback => '帮助与反馈';

  @override
  String get aboutEchat => '关于 E-Chat';

  @override
  String get contacts => '联系人';

  @override
  String get friendRequests => '好友申请';

  @override
  String get errorSessionExpired => '登录已失效，请重新登录。';

  @override
  String get errorMissingPasswordCredentials => '请输入用户 ID 和密码。';

  @override
  String get errorMissingTokenCredentials => '请输入用户 ID 和 Chat Token。';

  @override
  String errorLogoutFailed(String detail) {
    return '退出登录失败：$detail';
  }

  @override
  String get errorGroupNameRequired => '请输入群名称。';

  @override
  String get errorGroupMembersRequired => '请至少选择一名成员。';

  @override
  String get errorAddFriendIdRequired => '请输入 Agora Chat 用户 ID。';

  @override
  String get errorAttachmentPathExpired => '附件路径已失效，请重新选择文件后发送。';

  @override
  String errorImagePickFailed(String detail) {
    return '无法选择图片：$detail';
  }

  @override
  String get errorMicrophonePermission => '需要麦克风权限才能录制语音消息。';

  @override
  String errorRecordingStartFailed(String detail) {
    return '无法开始录音：$detail';
  }

  @override
  String get errorRecordingTooShort => '录音太短，请至少录制 1 秒。';

  @override
  String errorRecordingStopFailed(String detail) {
    return '录音失败：$detail';
  }

  @override
  String get errorVoiceNotDownloaded => '语音文件尚未下载。';

  @override
  String errorVoicePlaybackFailed(String detail) {
    return '无法播放语音：$detail';
  }

  @override
  String get errorUnknown => '发生了未知错误，请稍后重试。';

  @override
  String get errorChatUnavailable => '聊天服务暂时不可用，请稍后重试。';

  @override
  String get errorPlatformUnsupported => 'Agora Chat 当前仅支持 Android/iOS。';
}
