// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Namida Charts';

  @override
  String get homeTitle => '主页';

  @override
  String get settingsTitle => '设置';

  @override
  String get optionalPath => '本地音乐文件夹';

  @override
  String get metadataExtraction => '匹配本地音乐文件以补充元数据信息';

  @override
  String get chooseDirectory => '选择文件夹';

  @override
  String get language => '语言';

  @override
  String get english => 'English';

  @override
  String get chinese => '中文';

  @override
  String get themeMode => '主题';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get chooseBackupZip => '请选择 Namida 备份 ZIP 文件 (可多选)';

  @override
  String get allTime => '所有时间';

  @override
  String get chooseMusicFolder => '选择音乐文件夹';

  @override
  String get clearPath => '清除路径';

  @override
  String get done => '完成';

  @override
  String get extractingMessage => '正在解压与分析…\\n这可能需要一些时间。';

  @override
  String progressExtracting(int current, int total) {
    return '正在解压文件… ($current/$total)';
  }

  @override
  String get progressScanning => '正在扫描本地音乐文件…';

  @override
  String get progressAnalyzing => '正在分析数据与生成报告…';

  @override
  String get progressCleanup => '正在清理临时文件…';

  @override
  String get analysisComplete => '分析完成！';

  @override
  String get errorTitle => '错误';

  @override
  String get ok => '确定';

  @override
  String get welcomeMessage => '欢迎使用 Namida Charts';

  @override
  String get selectBackupZip => '选择备份 ZIP';

  @override
  String get namidaHistory => 'Namida Charts';

  @override
  String get resetAndSelectNewFile => '重置并选择新文件';

  @override
  String get viewFullList => '查看总榜';

  @override
  String get monthlyTopSong => '每月主打歌';

  @override
  String get noTrackDetails => '暂无该单曲的详细信息';

  @override
  String get playsSuffix => '次';

  @override
  String get historyTitle => '历史时刻';

  @override
  String get firstPlayLabel => '加入/首次听歌';

  @override
  String get lastPlayLabel => '最后一次听歌';

  @override
  String get unknownLabel => '未知';

  @override
  String get playTrend => '播放趋势';

  @override
  String get sectionCoreNumbers => '1. 核心数字 (全年轮廓)';

  @override
  String get sectionTopLists => '2. 年度排行榜';

  @override
  String get sectionTimeDimension => '3. 时间维度与听歌作息';

  @override
  String get sectionHighlights => '4. 高光与极值时刻';

  @override
  String get sectionPlayHistoryTrend => '播放历史趋势';

  @override
  String get statTotalListening => '听歌总计';

  @override
  String get statListeningCompanion => '听歌陪伴';

  @override
  String get statAvgDaily => '日均时长';

  @override
  String get statTotalPlays => '累计播放';

  @override
  String get statUniqueTracks => '探索单曲';

  @override
  String get statUniqueArtists => '探索歌手';

  @override
  String get statUniqueAlbums => '探索专辑';

  @override
  String get statFavoriteGenre => '最爱流派';

  @override
  String get hoursUnit => '小时';

  @override
  String get daysUnit => '天';

  @override
  String get minutesUnit => '分钟';

  @override
  String get tracksUnit => '首';

  @override
  String get artistsUnit => '位';

  @override
  String get albumsUnit => '张';

  @override
  String annualTopTracks(int count) {
    return '年度最爱单曲 Top $count';
  }

  @override
  String annualTopArtists(int count) {
    return '年度最爱歌手 Top $count';
  }

  @override
  String annualTopAlbums(int count) {
    return '年度最爱专辑 Top $count';
  }

  @override
  String get highlightRepeatTitle => '执念时刻：单曲循环之最';

  @override
  String highlightRepeatBody(Object count, Object date, Object track) {
    return '【$date】这一天一定很特别，\\n你把《$track》单曲循环了 $count 遍。';
  }

  @override
  String get latestNightTitle => '最晚的夜';

  @override
  String latestNightBody(Object time, Object track) {
    return '全年在凌晨最晚的一次听歌是 $time，\\n这首歌是《$track》。';
  }

  @override
  String get mostImmersiveTitle => '最沉浸的一天';

  @override
  String mostImmersiveBody(Object count, Object date) {
    return '【$date】 是你在音乐里最沉浸的一天，\\n全天一共播放了 $count 次。';
  }

  @override
  String get periodNight => '凌晨';

  @override
  String get periodMorning => '上午';

  @override
  String get periodAfternoon => '下午';

  @override
  String get periodEvening => '夜晚';

  @override
  String get weekMon => '周一';

  @override
  String get weekTue => '周二';

  @override
  String get weekWed => '周三';

  @override
  String get weekThu => '周四';

  @override
  String get weekFri => '周五';

  @override
  String get weekSat => '周六';

  @override
  String get weekSun => '周日';

  @override
  String get periodDistributionTitle => '时段分布';

  @override
  String get weeklyPatternTitle => '一周规律';

  @override
  String artistTopSongsTitle(int count) {
    return '歌手热歌 Top $count';
  }

  @override
  String albumTopSongsTitle(int count) {
    return '专辑热歌 Top $count';
  }

  @override
  String get noItemDetails => '暂无该项目详细信息';

  @override
  String get tabOverview => '概览';

  @override
  String get tabTopSongs => '热门曲目';

  @override
  String get tabTrend => '趋势';

  @override
  String get fullListSuffix => '总榜';

  @override
  String get noDataAvailable => '暂无数据。';

  @override
  String get namidaPathLabel => 'Namida 播放器路径';

  @override
  String get namidaPathHint => '设置后可直接在 Namida 中播放歌曲';

  @override
  String get namidaAndroidHint => '将通过 Android Intent 自动启动 Namida 应用';

  @override
  String get chooseNamidaExe => '选择 namida.exe';

  @override
  String get playInNamida => '在 Namida 中播放';

  @override
  String get openWithDefault => '用默认播放器打开';

  @override
  String get fileNotFound => '未找到本地音乐文件';

  @override
  String get needMusicDir => '请先在设置中配置音乐文件夹路径';

  @override
  String get launchFailed => '启动失败';

  @override
  String get permissionDenied => '存储权限被拒绝，无法读取音乐文件';

  @override
  String get settingsCoreNumbers => '核心数字显示与排序';

  @override
  String get settingsTopTracksCount => '年度最爱单曲 Top N';

  @override
  String get settingsTopArtistsCount => '年度最爱歌手 Top N';

  @override
  String get settingsTopAlbumsCount => '年度最爱专辑 Top N';

  @override
  String get settingsMonthlyPreviewCount => '每月主打歌预览数量';

  @override
  String get settingsMonthFormat => '月份显示格式';

  @override
  String get monthFormatNumeric => '数字 (1, 2, 3...)';

  @override
  String get monthFormatEnglish => '英文 (Jan. Feb. Mar...)';

  @override
  String get settingsDisplaySection => '显示设置';

  @override
  String get settingsPathSection => '路径设置';

  @override
  String get settingsGeneralSection => '通用设置';

  @override
  String get dragToReorder => '拖动到上半部分显示，下半部分隐藏，点击切换';

  @override
  String get visible => '显示';

  @override
  String get hidden => '隐藏';

  @override
  String get settingsFontSize => '字体大小';

  @override
  String settingsFontSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get monthlyRanking => '榜单';

  @override
  String get monthlyUniqueTracks => '首歌曲';
}
