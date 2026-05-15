import { common } from '@kit.AbilityKit'
import { cloudData, relationalStore, uniformTypeDescriptor } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalTodoList } from '../common/Dataget'
import { write } from '../common/File'
import { checkPermission } from '../common/Permission'
import { getFlushPreference, setFlushPreference } from '../common/Preference'
import { getSizeString } from '../common/Stringformat'
import { syncTable, systemCalendarSyncTable } from '../common/Table'

interface Item {
  deviceId: string,
  deviceName: string,
  deviceType: string,
  networkId: string
}

@Builder
export function TablesyncBuilder() {
  Tablesync()
}

@ComponentV2
struct Tablesync {
  @Local on: boolean = false
  @Local huaweiCloudSyncOn: boolean = false
  @Local autoSyncDevices: Item[] = []
  @Local availableDeviceArray: Item[] = []
  @Local huaweiCloudSyncProgressDetails: relationalStore.ProgressDetails | undefined = undefined
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  index = 0
  value = '始终'
  autoSync = false
  autoHuaweiCloudSync = false
  autoSystemCalendarSync = false
  pauseAutoSyncWhenLowBatteryCapacityLevel = false
  pauseAutoSyncWhenPowerSave = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '进行中...'
    })
  })

  getSetting() {
    this.on = getFlushPreference(this.context, 'dataSetting', 'on', false) as boolean
    this.autoSync = getFlushPreference(this.context, 'dataSetting', 'autoSync', false) as boolean
    this.autoSyncDevices = getFlushPreference(this.context, 'dataSetting', 'autoSyncDevices', []) as Item[]
    const index = getFlushPreference(this.context, 'dataSetting', 'huaweiCloudSyncNetworkStrategy', 0)
    this.index = index as number
    if (index === 0) {
      this.value = '始终'
    }
    if (index === 1) {
      this.value = '仅 WLAN 下'
    }
    this.huaweiCloudSyncOn = getFlushPreference(this.context, 'dataSetting', 'huaweiCloudSyncOn', false) as boolean
    this.autoHuaweiCloudSync = getFlushPreference(this.context, 'dataSetting', 'autoHuaweiCloudSync', false) as boolean
    this.autoSystemCalendarSync =
      getFlushPreference(this.context, 'dataSetting', 'autoSystemCalendarSync', false) as boolean
    this.pauseAutoSyncWhenLowBatteryCapacityLevel =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoSyncWhenPowerSave =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', false) as boolean
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Column() {
            Text('可信设备')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('状态')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.on!!
                })
                  .enabled(!this.on)
                  .onChange(async (isOn) => {
                    if (isOn) {
                      const res = await checkPermission(this.context, this.UIContext,
                        'ohos.permission.DISTRIBUTED_DATASYNC')
                      if (!res) {
                        this.on = false
                      }
                      if (res) {
                        const rdbStore = await relationalStore.getRdbStore(this.context, {
                          name: 'todo',
                          securityLevel: relationalStore.SecurityLevel.S1,
                          encrypt: true,
                          allowRebuild: true
                        })
                        await rdbStore.setDistributedTables(['todo'],
                          relationalStore.DistributedType.DISTRIBUTED_DEVICE, {
                            autoSync: false
                          })
                        setFlushPreference(this.context, 'dataSetting', 'on', isOn)
                      }
                    }
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('自动同步')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoSync!!
                })
                  .enabled(this.on)
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoSync', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Text('自动同步 (推送) 到以下设备')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.autoSyncDevices, (item: Item, index) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('名称')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceType === 'PHONE' ? '手机' :
                  item.deviceType === 'TABLET' ? '平板' :
                    item.deviceType === '2IN1' ? '电脑' :
                      item.deviceType === 'WATCH' ? '手表' : 'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('网络标识')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('关闭自动同步')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '0,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = '0,' + index
                }
              })
              .onClick(async () => {
                const autoSyncDevices = this.autoSyncDevices.filter(device => device.deviceId !== item.deviceId)
                setFlushPreference(this.context, 'dataSetting', 'autoSyncDevices', autoSyncDevices)
                await promptAction.openToast({
                  message: '已关闭'
                })
                this.getSetting()
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
        if (this.autoSyncDevices.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem() {
          Row() {
            Text('可信设备')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Button('刷新')
              .onClick(async () => {
                this.availableDeviceArray =
                  distributedDeviceManager.createDeviceManager('com.zhangxm.aitodo')
                    .getAvailableDeviceListSync() as Item[]
                await promptAction.openToast({
                  message: '刷新成功'
                })
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.availableDeviceArray, (item: Item, index) => {
          ListItem() {
            Column() {
              Row() {
                Text('标识符')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('名称')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceName)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.deviceType === 'PHONE' ? '手机' :
                  item.deviceType === 'TABLET' ? '平板' :
                    item.deviceType === '2IN1' ? '电脑' :
                      item.deviceType === 'WATCH' ? '手表' : 'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('网络标识')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.networkId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              if (!this.autoSyncDevices.find(device => device.deviceId === item.deviceId)) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('开启自动同步')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius(12)
                .padding(12)
                .stateStyles({
                  normal: {
                    .backgroundColor(this.hoverId === '1,' + index ? $r('sys.color.interactive_hover') :
                      $r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .onHover(isHover => {
                  if (!isHover) {
                    this.hoverId = -1
                  }
                  if (isHover) {
                    this.hoverId = '1,' + index
                  }
                })
                .onClick(async () => {
                  this.autoSyncDevices = Array.from(new Set([...this.autoSyncDevices, item]))
                  setFlushPreference(this.context, 'dataSetting', 'autoSyncDevices', this.autoSyncDevices)
                  await promptAction.openToast({
                    message: '已开启'
                  })
                })
              }
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('推送')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '2,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = '2,' + index
                }
              })
              .onClick(async () => {
                if (!this.on) {
                  await promptAction.openToast({
                    message: '请先开启上方状态开关'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                await syncTable(this.context, item.networkId, relationalStore.SyncMode.SYNC_MODE_PUSH)
                this.dialogControllerProgress.close()
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('拉取')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '3,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = '3,' + index
                }
              })
              .onClick(async () => {
                if (!this.on) {
                  await promptAction.openToast({
                    message: '请先开启上方状态开关'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                await syncTable(this.context, item.networkId, relationalStore.SyncMode.SYNC_MODE_PULL)
                this.dialogControllerProgress.close()
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
        if (this.availableDeviceArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem() {
          Column() {
            Text('华为云空间')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('同步时机')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Select([
                  { value: '始终' },
                  { value: '仅 WLAN 下' }
                ])
                  .selected(this.index!!)
                  .value(this.value!!)
                  .onSelect(async (index) => {
                    if (index === 0) {
                      await cloudData.setCloudStrategy(cloudData.StrategyType.NETWORK,
                        [cloudData.NetWorkStrategy.WIFI, cloudData.NetWorkStrategy.CELLULAR])
                    }
                    if (index === 1) {
                      await cloudData.setCloudStrategy(cloudData.StrategyType.NETWORK,
                        [cloudData.NetWorkStrategy.WIFI])
                    }
                    setFlushPreference(this.context, 'dataSetting', 'huaweiCloudSyncNetworkStrategy', index)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('状态')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.huaweiCloudSyncOn!!
                })
                  .enabled(!this.huaweiCloudSyncOn)
                  .onChange(async (isOn) => {
                    if (isOn) {
                      const rdbStore = await relationalStore.getRdbStore(this.context, {
                        name: 'huaweicloudsync',
                        securityLevel: relationalStore.SecurityLevel.S1,
                        encrypt: true,
                        allowRebuild: true
                      })
                      await rdbStore.setDistributedTables(['todo'], relationalStore.DistributedType.DISTRIBUTED_CLOUD, {
                        autoSync: false
                      })
                      setFlushPreference(this.context, 'dataSetting', 'huaweiCloudSyncOn', isOn)
                    }
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('自动同步')
                    .fontWeight(FontWeight.Medium)
                  Text('从修改时间较近的一端同步到修改时间较远的一端')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoHuaweiCloudSync!!
                })
                  .enabled(this.huaweiCloudSyncOn)
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoHuaweiCloudSync', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('手动同步')
                    .fontWeight(FontWeight.Medium)
                  if (this.huaweiCloudSyncProgressDetails) {
                    Text() {
                      Span(this.huaweiCloudSyncProgressDetails.schedule === relationalStore.Progress.SYNC_BEGIN ?
                        '同步开始\n' :
                        this.huaweiCloudSyncProgressDetails.schedule === relationalStore.Progress.SYNC_IN_PROGRESS ?
                          '同步中\n' :
                          this.huaweiCloudSyncProgressDetails.schedule === relationalStore.Progress.SYNC_FINISH ?
                            '同步完成\n' : 'undefined\n')
                        .fontColor(this.huaweiCloudSyncProgressDetails.schedule ===
                          relationalStore.Progress.SYNC_BEGIN ? $r('sys.color.font_secondary') :
                          this.huaweiCloudSyncProgressDetails.schedule === relationalStore.Progress.SYNC_IN_PROGRESS ?
                            Color.Orange : Color.Green)
                      Span(this.huaweiCloudSyncProgressDetails.code === relationalStore.ProgressCode.SUCCESS ?
                        '同步成功' :
                        this.huaweiCloudSyncProgressDetails.code === relationalStore.ProgressCode.UNKNOWN_ERROR ?
                          '同步过程遇到未知错误' :
                          this.huaweiCloudSyncProgressDetails.code === relationalStore.ProgressCode.NETWORK_ERROR ?
                            '同步过程遇到网络错误' :
                            this.huaweiCloudSyncProgressDetails.code === relationalStore.ProgressCode.CLOUD_DISABLED ?
                              '云端不可用' :
                              this.huaweiCloudSyncProgressDetails.code ===
                                relationalStore.ProgressCode.LOCKED_BY_OTHERS ?
                                '有其他设备正在同步，本设备当前无法进行同步' :
                                this.huaweiCloudSyncProgressDetails.code ===
                                  relationalStore.ProgressCode.RECORD_LIMIT_EXCEEDED ? '本次同步条目或大小超出最大值' :
                                  this.huaweiCloudSyncProgressDetails.code ===
                                    relationalStore.ProgressCode.NO_SPACE_FOR_ASSET ? '云空间剩余空间小于待同步大小' :
                                    this.huaweiCloudSyncProgressDetails.code ===
                                      relationalStore.ProgressCode.BLOCKED_BY_NETWORK_STRATEGY ? '同步被网络策略限制' :
                                      'undefined')
                        .fontColor(this.huaweiCloudSyncProgressDetails.code === relationalStore.ProgressCode.SUCCESS ?
                          Color.Green : Color.Red)
                      if (this.huaweiCloudSyncProgressDetails.details['todo']) {
                        Span('\n上传：')
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].upload.total))
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].upload.remained))
                          .fontColor(Color.Orange)
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].upload.successful))
                          .fontColor(Color.Green)
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].upload.failed))
                          .fontColor(Color.Red)
                        Span('\n下载：')
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].download.total))
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].download.remained))
                          .fontColor(Color.Orange)
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].download.successful))
                          .fontColor(Color.Green)
                        Span('/')
                          .fontColor($r('sys.color.font_secondary'))
                        Span(String(this.huaweiCloudSyncProgressDetails.details['todo'].download.failed))
                          .fontColor(Color.Red)
                      }
                    }
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Image($r('app.media.up'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    if (!this.huaweiCloudSyncOn) {
                      await promptAction.openToast({
                        message: '请先开启上方状态开关'
                      })
                      return
                    }
                    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'huaweicloudsync',
                      securityLevel: relationalStore.SecurityLevel.S1,
                      encrypt: true,
                      allowRebuild: true
                    })
                    await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_NATIVE_FIRST, ['todo'],
                      (progressDetails) => {
                        this.huaweiCloudSyncProgressDetails = progressDetails
                      })
                  })
                Image($r('app.media.down'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    if (!this.huaweiCloudSyncOn) {
                      await promptAction.openToast({
                        message: '请先开启上方状态开关'
                      })
                      return
                    }
                    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'huaweicloudsync',
                      securityLevel: relationalStore.SecurityLevel.S1,
                      encrypt: true,
                      allowRebuild: true
                    })
                    await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_CLOUD_FIRST, ['todo'],
                      (progressDetails) => {
                        this.huaweiCloudSyncProgressDetails = progressDetails
                      })
                  })
                Image($r('app.media.time'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    if (!this.huaweiCloudSyncOn) {
                      await promptAction.openToast({
                        message: '请先开启上方状态开关'
                      })
                      return
                    }
                    const huaweiCloudSyncRdbStore = await relationalStore.getRdbStore(this.context, {
                      name: 'huaweicloudsync',
                      securityLevel: relationalStore.SecurityLevel.S1,
                      encrypt: true,
                      allowRebuild: true
                    })
                    await huaweiCloudSyncRdbStore.cloudSync(relationalStore.SyncMode.SYNC_MODE_TIME_FIRST, ['todo'],
                      (progressDetails) => {
                        this.huaweiCloudSyncProgressDetails = progressDetails
                      })
                  })
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text() {
              Span('使用前请')
                .fontColor($r('sys.color.font_secondary'))
              Span('点此')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(async () => {
                  await this.context.openLink('hicloud://cloudDrive/getInfo?path=MainActivity')
                })
              Span('前往系统云空间设置页面开启本应用的云空间同步功能。')
                .fontColor($r('sys.color.font_secondary'))
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .margin({
              top: 6,
              left: 12,
              right: 12
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('系统日历')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('自动同步 (推送)')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoSystemCalendarSync!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoSystemCalendarSync', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('手动同步')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 2
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '选择同步模式',
                  buttons: [
                    {
                      text: '推送 (本应用 > 系统日历)',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '拉取 (系统日历 > 本应用)',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                let res = ''
                if (data.index === 0) {
                  res = await systemCalendarSyncTable(this.context, 'push')
                }
                if (data.index === 1) {
                  res = await systemCalendarSyncTable(this.context, 'pull')
                }
                if (res === 'success') {
                  await promptAction.openToast({
                    message: '同步成功'
                  })
                }
                if (res === 'fail') {
                  await promptAction.openToast({
                    message: '同步失败'
                  })
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('暂停自动同步')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('电池电量低')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoSyncWhenLowBatteryCapacityLevel!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'pauseAutoSyncWhenLowBatteryCapacityLevel',
                      isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('系统开启 (超级) 省电模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoSyncWhenPowerSave!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'pauseAutoSyncWhenPowerSave', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('碰一碰 / 隔空传送')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('待办')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = 1
                }
              })
              .onClick(async () => {
                const array = await getPersonalTodoList(this.context)
                const filePath = this.context.tempDir + '/todo.txt'
                await write(filePath, JSON.stringify(array))
                const shareData = new systemShare.SharedData({
                  utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
                  title: 'todo.txt',
                  description: getSizeString(fileIo.statSync(filePath).size),
                  uri: fileUri.getUriFromPath(filePath)
                })
                harmonyShare.on('knockShare', async (sharableTarget) => {
                  await sharableTarget.share(shareData)
                })
                harmonyShare.on('gesturesShare', async (sharableTarget) => {
                  await sharableTarget.share(shareData)
                })
                const promptAction = this.UIContext.getPromptAction()
                await promptAction.showDialog({
                  title: '提示',
                  message: '碰一碰/隔空传送邻近设备即可同步，关闭此弹窗后停止同步',
                  buttons: [
                    {
                      text: '关闭',
                      color: $r('sys.color.warning')
                    }
                  ],
                  onDidDisappear: async () => {
                    await fileIo.unlink(filePath)
                    harmonyShare.off('knockShare')
                    harmonyShare.off('gesturesShare')
                  }
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '设备间数据同步'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      this.getSetting()
      const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.DISTRIBUTED_DATASYNC')
      if (res) {
        this.availableDeviceArray = distributedDeviceManager.createDeviceManager('com.zhangxm.aitodo')
          .getAvailableDeviceListSync() as Item[]
      }
      await checkPermission(this.context, this.UIContext, 'ohos.permission.READ_CALENDAR')
      await checkPermission(this.context, this.UIContext, 'ohos.permission.WRITE_CALENDAR')
    })
  }
}