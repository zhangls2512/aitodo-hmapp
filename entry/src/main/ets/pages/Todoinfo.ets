import { common, Want, wantConstant } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { calendarManager } from '@kit.CalendarKit'
import { fileShare } from '@kit.CoreFileKit'
import { mapCommon, MapComponent, petalMaps } from '@kit.MapKit'
import { filePreview } from '@kit.PreviewKit'
import { call } from '@kit.TelephonyKit'
import { Action } from '../common/Datachange'
import { getTodoInfo, TeamCompleteTimeItem, Todo } from '../common/Dataget'
import { icsTimeStringToTimeStamp } from '../common/Ics'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'
import { getFlushPreference } from '../common/Preference'
import { isProxyReminderOn } from '../common/Proxyreminder'
import { teamRequest } from '../common/Request'
import { getDateTimeStringFromTimeStamp, stringSplit } from '../common/Stringformat'
import { getSystemCalendarEvent, SystemCalendarEvent } from '../common/Table'

export interface OpenAppByTypeValue {
  type: string,
  wantParam: Record<string, Object>
}

@ComponentV2
export default struct Todoinfo {
  @Param todoId: string = ''
  @Param teamId: string = ''
  @Param todoInfo: string = ''
  @Local content: string = ''
  @Local priority: number = 0
  @Local startTime: number = Date.now()
  @Local remind: boolean = false
  @Local endTime: number = -1
  @Local duration: number = 0
  @Local recurrence: boolean = false
  @Local recurrenceFreq: string = ''
  @Local recurrenceInterval: string = '1'
  @Local recurrenceUntil: number = -1
  @Local recurrenceCount: string = '0'
  @Local recurrenceByMonth: number[] = []
  @Local recurrenceByMonthDay: number[] = []
  @Local recurrenceByDay: string[] = []
  @Local tag: string[] = []
  @Local dependency: string[] = []
  @Local locationLatitude: number = -1
  @Local locationLongitude: number = -1
  @Local locationLocation: string = ''
  @Local action: Action[] = []
  @Local bz: string = ''
  @Local completeMode: string | undefined = undefined
  @Local allowCompleteUids: string[] | undefined = undefined
  @Local allowGetUids: string[] | undefined = undefined
  @Local allowReviewUids: string[] | undefined = undefined
  @Local recentCompleteTime: TeamCompleteTimeItem[] | undefined = undefined
  @Local reviewRecentCompleteTime: TeamCompleteTimeItem[] | undefined = undefined
  @Local systemCalendarEvent: SystemCalendarEvent[] = []
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  freqMap: Record<string, string> = {
    'YEARLY': '年',
    'MONTHLY': '月',
    'WEEKLY': '周',
    'DAILY': '日'
  }
  dayMap: Record<string, string> = {
    'MO': '星期一',
    'TU': '星期二',
    'WE': '星期三',
    'TH': '星期四',
    'FR': '星期五',
    'SA': '星期六',
    'SU': '星期日'
  }
  actionTypeMap: Record<string, string> = {
    'openApp': '打开应用',
    'openAppByType': '打开指定类型应用',
    'openUrl': '打开链接',
    'openFile': '打开文件',
    'callTelephone': '拨号'
  }

  getDayNightMode() {
    const colorMode = getFlushPreference(this.context, 'commonSetting', 'colorMode', 0)
    if (colorMode === 0) {
      return mapCommon.DayNightMode.AUTO
    }
    if (colorMode === 1) {
      return mapCommon.DayNightMode.DAY
    }
    if (colorMode === 2) {
      return mapCommon.DayNightMode.NIGHT
    }
    return mapCommon.DayNightMode.AUTO
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Text(this.content)
            .enableAutoSpacing(true)
            .enableDataDetector(true)
            .fontWeight(FontWeight.Bold)
          Text() {
            Span('ID：')
              .fontWeight(FontWeight.Medium)
            Span(this.todoId)
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(async () => {
                await copy(this.context, this.UIContext, this.todoId)
              })
          }
          .margin({
            top: $r('sys.float.ohos_id_text_margin_vertical')
          })

          Text() {
            Span('优先级：')
              .fontWeight(FontWeight.Medium)
            Span(String(this.priority))
          }
          .margin({
            top: $r('sys.float.ohos_id_text_margin_vertical')
          })

          Text() {
            Span('开始时间：')
              .fontWeight(FontWeight.Medium)
            Span(getDateTimeStringFromTimeStamp(this.startTime))
          }
          .enableAutoSpacing(true)
          .margin({
            top: $r('sys.float.ohos_id_text_margin_vertical')
          })

          if (!this.teamId && !this.recurrence) {
            Text() {
              Span('提醒：')
                .fontWeight(FontWeight.Medium)
              Span(this.remind ? '开' : '关')
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.endTime !== -1) {
            Text() {
              Span('结束时间：')
                .fontWeight(FontWeight.Medium)
              Span(getDateTimeStringFromTimeStamp(this.endTime))
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.duration !== 0) {
            Text() {
              Span('预计耗时：')
                .fontWeight(FontWeight.Medium)
              Span(this.duration / 60000 + '分钟')
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.recurrence) {
            Text() {
              Span('重复周期：')
                .fontWeight(FontWeight.Medium)
              Span(this.recurrenceFreq)
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            if (['年', '月', '周', '日'].includes(this.recurrenceFreq)) {
              Text() {
                Span('重复步长：')
                  .fontWeight(FontWeight.Medium)
                Span(this.recurrenceInterval)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.recurrenceUntil !== -1) {
              Text() {
                Span('重复截止时间：')
                  .fontWeight(FontWeight.Medium)
                Span(getDateTimeStringFromTimeStamp(this.recurrenceUntil))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.recurrenceCount !== '0') {
              Text() {
                Span('最大重复次数：')
                  .fontWeight(FontWeight.Medium)
                Span(this.recurrenceCount)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.recurrenceByMonth.length > 0) {
              Text() {
                Span('重复月：')
                  .fontWeight(FontWeight.Medium)
                Span(this.recurrenceByMonth.map(item => item + '月').join('、'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.recurrenceByMonthDay.length > 0) {
              Text() {
                Span('重复日：')
                  .fontWeight(FontWeight.Medium)
                Span(this.recurrenceByMonthDay.map(item => item + '日').join('、'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.recurrenceByDay.length > 0) {
              Text() {
                Span('重复星期：')
                  .fontWeight(FontWeight.Medium)
                Span(this.recurrenceByDay.map(item => this.dayMap[item]).join('、'))
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
          }
          if (this.tag.length > 0) {
            Text() {
              Span('标签：')
                .fontWeight(FontWeight.Medium)
              Span(this.tag.join('、'))
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.dependency.length > 0) {
            Text() {
              Span('依赖待办：')
                .fontWeight(FontWeight.Medium)
              Span(this.dependency.join('、'))
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.locationLatitude !== -1 && this.locationLongitude !== -1) {
            Text() {
              Span('纬度：')
                .fontWeight(FontWeight.Medium)
              Span(String(this.locationLatitude))
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            Text() {
              Span('经度：')
                .fontWeight(FontWeight.Medium)
              Span(String(this.locationLongitude))
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            MapComponent({
              mapOptions: {
                position: {
                  target: {
                    latitude: this.locationLatitude,
                    longitude: this.locationLongitude
                  },
                  zoom: 17
                },
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomControlsEnabled: false,
                compassControlsEnabled: false,
                dayNightMode: this.getDayNightMode(),
                approveNumberEnabled: true
              },
              mapCallback: () => {
              }
            })
              .height(300)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            if (this.locationLocation) {
              Text() {
                Span('地点：')
                  .fontWeight(FontWeight.Medium)
                Span(this.locationLocation)
                  .fontColor($r('sys.color.font_emphasize'))
              }
              .enableAutoSpacing(true)
              .enableDataDetector(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
              .onClick(async () => {
                await petalMaps.openMapPoiDetail(this.context, {
                  destinationPosition: {
                    latitude: this.locationLatitude,
                    longitude: this.locationLongitude
                  }
                })
              })
            }
          }
          if (this.locationLocation && (this.locationLatitude === -1 || this.locationLongitude === -1)) {
            Text() {
              Span('地点：')
                .fontWeight(FontWeight.Medium)
              Span(this.locationLocation)
            }
            .enableAutoSpacing(true)
            .enableDataDetector(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.bz) {
            Text() {
              Span('备注：')
                .fontWeight(FontWeight.Medium)
              Span(this.bz)
            }
            .enableAutoSpacing(true)
            .enableDataDetector(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          if (this.teamId) {
            if (this.completeMode) {
              Text() {
                Span('完成模式：')
                  .fontWeight(FontWeight.Medium)
                Span(this.completeMode === 'single' ? '单用户' : '多用户')
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.allowCompleteUids) {
              Text() {
                Span('执行者：')
                  .fontWeight(FontWeight.Medium)
                Span(this.allowCompleteUids.join('、'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.allowGetUids) {
              Text() {
                Span('查看者：')
                  .fontWeight(FontWeight.Medium)
                Span(this.allowGetUids.join('、'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.allowReviewUids) {
              Text() {
                Span('审核者：')
                  .fontWeight(FontWeight.Medium)
                Span(this.allowReviewUids.join('、'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      if (this.action.length > 0) {
        ListItem() {
          Text('动作')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ForEach(this.action, (item: Action) => {
        ListItem() {
          Column() {
            Row() {
              Column() {
                Text(item.value)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Text(this.actionTypeMap[item.type])
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(async () => {
              if (item.type === 'openApp') {
                const want = JSON.parse(item.value) as Want
                await this.context.startAbility(want)
              }
              if (item.type === 'openAppByType') {
                const value = JSON.parse(item.value) as OpenAppByTypeValue
                await this.context.startAbilityByType(value.type, value.wantParam, {
                  onError: async (code, name, message) => {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + code + '，错误名称：' + name + '，错误信息：' + message
                    })
                  }
                })
              }
              if (item.type === 'openUrl') {
                await openLink(this.context, item.value)
              }
              if (item.type === 'openFile') {
                const permissions = await fileShare.checkPersistentPermission([{
                  uri: item.value,
                  operationMode: fileShare.OperationMode.READ_MODE
                }])
                const permission = permissions[0]
                if (!permission) {
                  await promptAction.openToast({
                    message: '无权限'
                  })
                }
                if (permission) {
                  await fileShare.activatePermission([{
                    uri: item.value,
                    operationMode: fileShare.OperationMode.READ_MODE
                  }])
                  const canPreview = await filePreview.canPreview(this.context, item.value)
                  if (!canPreview) {
                    await this.context.startAbility({
                      action: 'ohos.want.action.viewData',
                      uri: item.value,
                      parameters: {
                        'ohos.ability.params.showDefaultPicker': true
                      },
                      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
                    })
                  }
                  if (canPreview) {
                    await filePreview.openPreview(this.context, {
                      title: item.value.substring(item.value.lastIndexOf('/') + 1),
                      uri: item.value,
                      mimeType: ''
                    })
                  }
                }
              }
              if (item.type === 'callTelephone') {
                await call.makeCall(item.value)
              }
            })
            .gesture(
              LongPressGesture()
                .onAction(async () => {
                  await copy(this.context, this.UIContext, item.value)
                })
            )
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      if (this.systemCalendarEvent.length > 0) {
        ListItem() {
          Text('系统日历日程')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ForEach(this.systemCalendarEvent, (item: SystemCalendarEvent) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.systemCalendar.displayName ? item.systemCalendar.displayName : item.systemCalendar.name)
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(async () => {
              const systemCalendarManager = calendarManager.getCalendarManager(this.context)
              const calendar = await systemCalendarManager.getCalendar(item.systemCalendar)
              await calendar.openEventEditPage(item.eventId)
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      if (this.teamId) {
        if (this.recentCompleteTime) {
          ListItem() {
            Text('已审核完成情况')
              .fontWeight(FontWeight.Medium)
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })

          if (this.recentCompleteTime.length === 0) {
            ListItem() {
              Text('无数据')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
          }
          ForEach(this.recentCompleteTime, (item: TeamCompleteTimeItem) => {
            ListItem() {
              Column() {
                Text('名：' + item.uid)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Text('完成时间：' + getDateTimeStringFromTimeStamp(item.time))
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding(16)
              .width('100%')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          })
        }
        if (this.reviewRecentCompleteTime) {
          ListItem() {
            Text('待审核完成情况')
              .fontWeight(FontWeight.Medium)
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })

          if (this.reviewRecentCompleteTime.length === 0) {
            ListItem() {
              Text('无数据')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
          }
          ForEach(this.reviewRecentCompleteTime, (item: TeamCompleteTimeItem) => {
            ListItem() {
              Column() {
                Text('名：' + item.uid)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Text('完成时间：' + getDateTimeStringFromTimeStamp(item.time))
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding(16)
              .width('100%')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          })
        }
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      let todoInfo: Todo | undefined = undefined
      if (!this.teamId) {
        todoInfo = await getTodoInfo(this.context, this.todoId) as Todo
        this.systemCalendarEvent = await getSystemCalendarEvent(this.context, todoInfo.id)
      }
      if (this.teamId) {
        todoInfo = JSON.parse(this.todoInfo)
      }
      if (todoInfo) {
        this.content = todoInfo.content
        this.priority = todoInfo.priority
        this.startTime = todoInfo.startTime
        this.endTime = todoInfo.endTime
        this.duration = todoInfo.duration
        const recurrenceRule = todoInfo.recurrenceRule
        this.recurrence = recurrenceRule ? true : false
        if (this.recurrence) {
          const tokens = recurrenceRule.split(';')
          const keyValues = tokens.map((item): string[] => stringSplit(item, '=', 2))
          keyValues.forEach(item => {
            const key = item[0]
            const value = item[1]
            if (key === 'FREQ') {
              if (!this.freqMap[value]) {
                this.recurrenceFreq = value
              }
              if (this.freqMap[value]) {
                this.recurrenceFreq = this.freqMap[value]
              }
            }
            if (key === 'INTERVAL') {
              this.recurrenceInterval = value
            }
            if (key === 'UNTIL') {
              this.recurrenceUntil = icsTimeStringToTimeStamp(value, true)
            }
            if (key === 'COUNT') {
              this.recurrenceCount = value
            }
            if (key === 'BYMONTH') {
              this.recurrenceByMonth = value.split(',').map(item => Number(item))
            }
            if (key === 'BYMONTHDAY') {
              this.recurrenceByMonthDay = value.split(',').map(item => Number(item))
            }
            if (key === 'BYDAY') {
              this.recurrenceByDay = value.split(',')
            }
          })
        }
        this.tag = todoInfo.tag
        this.dependency = todoInfo.dependency
        this.locationLatitude = todoInfo.location.latitude
        this.locationLongitude = todoInfo.location.longitude
        this.locationLocation = todoInfo.location.location
        this.action = todoInfo.action
        this.bz = todoInfo.bz
        if (this.teamId) {
          this.completeMode = todoInfo.completeMode
          const allowCompleteUids = todoInfo.allowCompleteUids
          const allowGetUids = todoInfo.allowGetUids
          const allowReviewUids = todoInfo.allowReviewUids
          const recentCompleteTime = todoInfo.recentCompleteTime
          const reviewRecentCompleteTime = todoInfo.reviewRecentCompleteTime
          const userNameMap = new Map<string, string>()
          const dialogControllerProgress = new CustomDialogController({
            builder: LoadingDialog({
              content: '请求中...'
            })
          })
          dialogControllerProgress.open()
          if (allowCompleteUids) {
            for (let i = 0; i < allowCompleteUids.length; i++) {
              const item = allowCompleteUids[i]
              if (!userNameMap.has(item)) {
                const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                  id: item
                })
                if (res !== 'fail') {
                  userNameMap.set(item, JSON.parse(res).name)
                }
                if (res === 'fail') {
                  userNameMap.set(item, '未知')
                }
              }
              if (userNameMap.has(item)) {
                allowCompleteUids[i] = userNameMap.get(item) as string
              }
            }
          }
          this.allowCompleteUids = todoInfo.allowCompleteUids
          if (allowGetUids) {
            for (let i = 0; i < allowGetUids.length; i++) {
              const item = allowGetUids[i]
              if (!userNameMap.has(item)) {
                const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                  id: item
                })
                if (res !== 'fail') {
                  userNameMap.set(item, JSON.parse(res).name)
                }
                if (res === 'fail') {
                  userNameMap.set(item, '未知')
                }
              }
              if (userNameMap.has(item)) {
                allowGetUids[i] = userNameMap.get(item) as string
              }
            }
          }
          this.allowGetUids = todoInfo.allowGetUids
          if (allowReviewUids) {
            for (let i = 0; i < allowReviewUids.length; i++) {
              const item = allowReviewUids[i]
              if (!userNameMap.has(item)) {
                const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                  id: item
                })
                if (res !== 'fail') {
                  userNameMap.set(item, JSON.parse(res).name)
                }
                if (res === 'fail') {
                  userNameMap.set(item, '未知')
                }
              }
              if (userNameMap.has(item)) {
                allowReviewUids[i] = userNameMap.get(item) as string
              }
            }
          }
          this.allowReviewUids = todoInfo.allowReviewUids
          if (recentCompleteTime) {
            for (let i = 0; i < recentCompleteTime.length; i++) {
              const item = recentCompleteTime[i]
              if (!userNameMap.has(item.uid)) {
                const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                  id: item.uid
                })
                if (res !== 'fail') {
                  userNameMap.set(item.uid, JSON.parse(res).name)
                }
                if (res === 'fail') {
                  userNameMap.set(item.uid, '未知')
                }
              }
              if (userNameMap.has(item.uid)) {
                recentCompleteTime[i].uid = userNameMap.get(item.uid) as string
              }
            }
          }
          this.recentCompleteTime = todoInfo.recentCompleteTime
          if (reviewRecentCompleteTime) {
            for (let i = 0; i < reviewRecentCompleteTime.length; i++) {
              const item = reviewRecentCompleteTime[i]
              if (!userNameMap.has(item.uid)) {
                const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                  id: item.uid
                })
                if (res !== 'fail') {
                  userNameMap.set(item.uid, JSON.parse(res).name)
                }
                if (res === 'fail') {
                  userNameMap.set(item.uid, '未知')
                }
              }
              if (userNameMap.has(item.uid)) {
                reviewRecentCompleteTime[i].uid = userNameMap.get(item.uid) as string
              }
            }
          }
          this.reviewRecentCompleteTime = todoInfo.reviewRecentCompleteTime
          dialogControllerProgress.close()
        }
      }
      if (!this.teamId) {
        this.remind = await isProxyReminderOn(this.todoId)
      }
    })
  }
}