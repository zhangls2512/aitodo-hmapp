import { common } from '@kit.AbilityKit'
import { uri } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { scanBarcode, scanCore } from '@kit.ScanKit'
import { getPersonalAccountAccessToken, getPersonalAccountInfo, removeAccount } from '../common/Account'
import getCloudServiceStatus from '../common/Cloudservice'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'
import { getPreferType } from '../common/Prefertype'
import { developerRequest } from '../common/Request'
import { getTimeStringFromTimeStamp } from '../common/Stringformat'
import Cloudservice from './Cloudservice'
import Login from './Login'
import Setting from './Setting'
import Team from './Team'
import Vip from './Vip'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Provider() isShowCloudserviceSheet: boolean = false
  @Local preferType: number = 1
  @Local isShowVipSheet: boolean = false
  @Local isShowTeamSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local uid: string = ''
  @Local email: string = ''
  @Local endDate: string = ''
  @Local cloudService: boolean = false
  @Local cloudServiceLoading: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  async get() {
    const accountInfo = await getPersonalAccountInfo()
    this.uid = accountInfo.uid
    this.email = accountInfo.email
    this.endDate = getTimeStringFromTimeStamp(accountInfo.endDate)
    const accessToken = await getPersonalAccountAccessToken()
    if (accessToken) {
      this.cloudServiceLoading = true
      this.cloudService = await getCloudServiceStatus(this.context)
      this.cloudServiceLoading = false
    }
  }

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  CloudserviceSheetBuilder() {
    Cloudservice()
  }

  @Builder
  VipSheetBuilder() {
    Vip()
  }

  @Builder
  TeamSheetBuilder() {
    Team()
  }

  @Builder
  SettingSheetBuilder() {
    Setting()
  }

  build() {
    List() {
      ListItem()
        .margin({
          top: this.preferType === 0 ? 56 : 0
        })
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.foreground'))
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(40)
            if (!this.uid) {
              Text('登录')
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
            if (this.uid) {
              if (!this.email) {
                Text('未绑定邮箱')
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
              if (this.email) {
                Text(this.email)
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
            }
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            if (!this.uid) {
              this.isShowLoginSheet = true
            }
          })
          .bindSheet(this.isShowLoginSheet!!, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            }
          })

          if (this.uid) {
            if (scanCore.isDefaultScanSupported()) {
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('扫码登录')
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
                  .backgroundColor($r('sys.color.comp_background_primary'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(async () => {
                try {
                  const promptAction = this.UIContext.getPromptAction()
                  const scanres = await scanBarcode.startScanForResult(this.context, {
                    scanTypes: [scanCore.ScanType.QR_CODE]
                  })
                  if (!scanres.originalValue.startsWith('https://www.zhangls2512.cn/product/account/login')) {
                    await promptAction.showDialog({
                      title: '提示',
                      message: '请扫描有效的登录二维码',
                      buttons: [
                        {
                          text: '确定',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    return
                  }
                  const uriInstance = new uri.URI(scanres.originalValue)
                  const ticket = uriInstance.getQueryValue('ticket')
                  if (!ticket) {
                    await promptAction.showDialog({
                      title: '提示',
                      message: '链接格式错误',
                      buttons: [
                        {
                          text: '确定',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                  }
                  if (ticket) {
                    const accessToken = await getPersonalAccountAccessToken()
                    if (!accessToken) {
                      await promptAction.showDialog({
                        title: '提示',
                        message: '扫码登录失败，原因：未登录账号',
                        buttons: [
                          {
                            text: '确定',
                            color: $r('sys.color.font_emphasize')
                          }
                        ]
                      })
                    }
                    if (accessToken) {
                      const confirm = await promptAction.showDialog({
                        title: '提示',
                        message: '确定登录？',
                        buttons: [
                          {
                            text: '取消',
                            color: $r('sys.color.font_primary')
                          },
                          {
                            text: '确定',
                            color: $r('sys.color.font_emphasize')
                          }
                        ]
                      })
                      if (confirm.index === 1) {
                        const dialogControllerProgress = new CustomDialogController({
                          builder: LoadingDialog({
                            content: '请求中...'
                          })
                        })
                        dialogControllerProgress.open()
                        const res = await developerRequest(this.context, '/account/confirmTicket', {
                          accessToken: accessToken,
                          ticket: ticket
                        })
                        dialogControllerProgress.close()
                        if (res !== 'fail') {
                          await promptAction.showDialog({
                            title: '提示',
                            message: '确定成功',
                            buttons: [
                              {
                                text: '确定',
                                color: $r('sys.color.font_emphasize')
                              }
                            ]
                          })
                        }
                      }
                    }
                  }
                } catch (err) {
                  if (err.code !== 1000500002) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
                    })
                  }
                }
              })
            }
            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('UID')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.uid)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.comp_background_primary'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .onClick(async () => {
              await copy(this.context, this.UIContext, this.uid)
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('登录到期时间：' + this.endDate)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text('去修改')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
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
                .backgroundColor($r('sys.color.comp_background_primary'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .onClick(async () => {
              await openLink(this.context, 'https://www.zhangls2512.cn/product/account/info')
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('云服务')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (!this.cloudServiceLoading) {
                if (!this.cloudService) {
                  Text('未开通')
                    .fontColor($r('sys.color.warning'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                }
                if (this.cloudService) {
                  Text('已开通')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                    })
                }
              }
              if (this.cloudServiceLoading) {
                LoadingProgress()
                  .height(14)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                  .width(14)
              }
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.comp_background_primary'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .onClick(() => {
              this.isShowCloudserviceSheet = true
            })
            .bindSheet(this.isShowCloudserviceSheet!!, this.CloudserviceSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '云服务'
              }
            })

            if (this.cloudService && !this.cloudServiceLoading) {
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('会员中心')
                  .fontColor('#FFD700')
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
                  .backgroundColor($r('sys.color.comp_background_primary'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(() => {
                this.isShowVipSheet = true
              })
              .bindSheet(this.isShowVipSheet!!, this.VipSheetBuilder(), {
                preferType: this.preferType
              })
            }
          }
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }

      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.users'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('团队')
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
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            this.isShowTeamSheet = true
          })
          .bindSheet(this.isShowTeamSheet!!, this.TeamSheetBuilder(), {
            preferType: this.preferType
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.setting'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('设置')
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
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            this.isShowSettingSheet = true
          })
          .bindSheet(this.isShowSettingSheet!!, this.SettingSheetBuilder(), {
            preferType: this.preferType
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.uid) {
        ListItem() {
          Button('退出登录')
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              const data = await promptAction.showDialog({
                title: '提示',
                message: '确定退出登录？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '退出',
                    color: $r('sys.color.warning')
                  }
                ]
              })
              if (data.index === 1) {
                await removeAccount('personal')
                await promptAction.openToast({
                  message: '退出成功'
                })
                this.uid = ''
                this.email = ''
                this.endDate = ''
                this.cloudService = false
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ListItem()
        .margin({
          bottom: this.preferType === 0 ? 80 : 0
        })
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshMe', async () => {
        await this.get()
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
    })
  }
}