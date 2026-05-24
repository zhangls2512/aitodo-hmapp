import { common } from '@kit.AbilityKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { relationalStore } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { formProvider } from '@kit.FormKit'
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken, getPersonalAccountInfo } from '../common/Account'
import { importCloudBackupTodo } from '../common/Cloudbackupimport'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import openLink from '../common/Openlink'
import { checkPermission } from '../common/Permission'
import { getFlushPreference, setFlushPreference } from '../common/Preference'
import { developerRequest } from '../common/Request'
import { Account } from './Huaweiaccount'

@ComponentV2
export default struct Setting {
  @Local allService: boolean = false
  @Local agreedPrivacyAgreement: number | undefined = undefined
  @Local email: string = ''
  @Local isBindHuaweiAccount: boolean = false
  @Local autoLoginByHuaweiAccount: boolean = false
  @Local autoLoginByPasskey: boolean = false
  @Local cloudService: boolean = false
  @Local accountLoading: boolean = false
  @Local accountDataSyncEnabled: boolean = false
  @Local accessToken: string = ''
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  accountDataSync = false
  autoCloudBackupOn = false
  autoCloudBackupImport = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  async getSetting() {
    this.allService = getFlushPreference(this.context, 'commonSetting', 'allService', true) as boolean
    try {
      const appPrivacyResults: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult()
      this.agreedPrivacyAgreement =
        appPrivacyResults.find(item => item.type === privacyManager.AppPrivacyType.PRIVACY_AGREEMENT)?.result
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
    }
    const accountInfo = await getPersonalAccountInfo()
    this.email = accountInfo.email
    this.accessToken = await getPersonalAccountAccessToken()
    if (this.accessToken) {
      const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.DISTRIBUTED_DATASYNC')
      this.accountDataSyncEnabled = res
      if (res) {
        const appAccountManager = appAccount.createAppAccountManager()
        this.accountDataSync = await appAccountManager.checkDataSyncEnabled('personal')
      }
      this.autoLoginByHuaweiAccount =
        getFlushPreference(this.context, 'commonSetting', 'autoLoginByHuaweiAccount', false) as boolean
      this.autoLoginByPasskey =
        getFlushPreference(this.context, 'commonSetting', 'autoLoginByPasskey', false) as boolean
      if (this.allService) {
        this.accountLoading = true
        const accountres = await developerRequest(this.context, '/account/getExternalAccount', {
          accessToken: this.accessToken
        })
        if (accountres !== 'fail') {
          const account = JSON.parse(accountres).data as Account[]
          this.isBindHuaweiAccount = account.some(item => item.platform === 'huawei')
        }
        this.cloudService = await getCloudServiceStatus(this.context)
        this.autoCloudBackupOn = getFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', false) as boolean
        this.autoCloudBackupImport =
          getFlushPreference(this.context, 'cloudbackupSetting', 'autoImport', false) as boolean
        this.accountLoading = false
      }
    }
  }

  build() {
    HdsNavigation(this.pageInfos) {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.accessToken) {
          ListItem() {
            Column() {
              Text('账号')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: 6,
                  left: 12,
                  right: 12
                })
              Column() {
                if (!this.email) {
                  Row() {
                    Text('绑定邮箱')
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
                      .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
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
                      this.hoverId = 0
                    }
                  })
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Email'
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                Row() {
                  if (!this.isBindHuaweiAccount) {
                    Text('绑定华为账号')
                      .fontColor($r('sys.color.font_emphasize'))
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                  }
                  if (this.isBindHuaweiAccount) {
                    Text('解绑华为账号')
                      .fontColor($r('sys.color.warning'))
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
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
                  if (!this.email) {
                    await promptAction.openToast({
                      message: '轩铭 2512 统一账号未绑定邮箱，无法使用此功能'
                    })
                    return
                  }
                  this.pageInfos.pushPath({
                    name: 'Huaweiaccount'
                  })
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Column() {
                    Text('华为账号静默登录')
                      .fontWeight(FontWeight.Medium)
                    Text('需绑定华为账号')
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
                    isOn: this.autoLoginByHuaweiAccount!!
                  })
                    .enabled(!this.autoLoginByPasskey)
                    .onChange(isOn => {
                      setFlushPreference(this.context, 'commonSetting', 'autoLoginByHuaweiAccount', isOn)
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
                  Text('新增通行密钥')
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
                  if (!this.email) {
                    await promptAction.openToast({
                      message: '轩铭 2512 统一账号未绑定邮箱，无法使用此功能'
                    })
                    return
                  }
                  this.pageInfos.pushPath({
                    name: 'Newpasskey'
                  })
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Column() {
                    Text('通行密钥静默登录')
                      .fontWeight(FontWeight.Medium)
                    Text('需新增通行密钥')
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
                    isOn: this.autoLoginByPasskey!!
                  })
                    .enabled(!this.autoLoginByHuaweiAccount)
                    .onChange(isOn => {
                      setFlushPreference(this.context, 'commonSetting', 'autoLoginByPasskey', isOn)
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
                  Text('设备间同步')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.accountDataSync!!
                  })
                    .enabled(this.accountDataSyncEnabled)
                    .onChange(async (isOn) => {
                      try {
                        const appAccountManager = appAccount.createAppAccountManager()
                        await appAccountManager.setDataSyncEnabled('personal', isOn)
                      } catch (err) {
                        this.accountDataSync = false
                        await promptAction.openToast({
                          message: '发生错误，错误码：' + err.code
                        })
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              Text('账号中心')
                .fontColor($r('sys.color.font_emphasize'))
                .fontSize($r('sys.float.ohos_id_text_size_body3'))
                .margin({
                  top: 6,
                  left: 12,
                  right: 12
                })
                .onClick(async () => {
                  await openLink(this.context, 'https://www.zhangls2512.cn/product/account/panel')
                })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          if (this.accountLoading) {
            ListItem() {
              LoadingProgress()
                .height(20)
                .width(20)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
          if (this.cloudService && !this.accountLoading) {
            ListItem() {
              Column() {
                Text('云备份')
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
                    Text('自动开启')
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.autoCloudBackupOn!!
                    })
                      .onChange(isOn => {
                        setFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', isOn)
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
                    Text('自动导入')
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.autoCloudBackupImport!!
                    })
                      .onChange(isOn => {
                        setFlushPreference(this.context, 'cloudbackupSetting', 'autoImport', isOn)
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
                    Text('导入')
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
                      .backgroundColor(this.hoverId === 3 ? $r('sys.color.interactive_hover') :
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
                      this.hoverId = 3
                    }
                  })
                  .onClick(async () => {
                    const promptAction = this.UIContext.getPromptAction()
                    if (!getKeyAlg()) {
                      const promptAction = this.UIContext.getPromptAction()
                      await promptAction.showDialog({
                        title: '导入失败',
                        message: '未导入密钥。请前往“我的”>“设置”>“密钥”导入密钥',
                        buttons: [
                          {
                            text: '确定',
                            color: $r('sys.color.font_emphasize')
                          }
                        ]
                      })
                      return
                    }
                    const data = await promptAction.showActionMenu({
                      title: '冲突解决模式',
                      buttons: [
                        {
                          text: '保留',
                          color: $r('sys.color.font_primary')
                        },
                        {
                          text: '覆盖',
                          color: $r('sys.color.font_primary')
                        }
                      ]
                    })
                    if (data.index === 0) {
                      this.dialogControllerProgress.open()
                      const res =
                        await importCloudBackupTodo(this.context, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
                      this.dialogControllerProgress.close()
                      if (res === 'success') {
                        await promptAction.openToast({
                          message: '导入成功'
                        })
                      }
                      if (res === 'fail') {
                        await promptAction.openToast({
                          message: '导入失败'
                        })
                      }
                    }
                    if (data.index === 1) {
                      this.dialogControllerProgress.open()
                      const res = await importCloudBackupTodo(this.context,
                        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE)
                      this.dialogControllerProgress.close()
                      if (res === 'success') {
                        await promptAction.openToast({
                          message: '导入成功'
                        })
                      }
                      if (res === 'fail') {
                        await promptAction.openToast({
                          message: '导入失败'
                        })
                      }
                    }
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('清理')
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
                      .backgroundColor(this.hoverId === 4 ? $r('sys.color.interactive_hover') :
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
                      this.hoverId = 4
                    }
                  })
                  .onClick(async () => {
                    const promptAction = this.UIContext.getPromptAction()
                    const data = await promptAction.showDialog({
                      title: '提示',
                      message: '清理成功后数据无法恢复。确定清理？',
                      buttons: [
                        {
                          text: '取消',
                          color: $r('sys.color.font_primary')
                        },
                        {
                          text: '清理',
                          color: $r('sys.color.warning')
                        }
                      ]
                    })
                    if (data.index === 1) {
                      this.dialogControllerProgress.open()
                      const res = await developerRequest(this.context, '/todo/clearBackup', {
                        accessToken: this.accessToken
                      })
                      this.dialogControllerProgress.close()
                      if (res !== 'fail') {
                        await promptAction.openToast({
                          message: '清理成功'
                        })
                      }
                    }
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Text('安全保障说明')
                  .fontColor($r('sys.color.font_emphasize'))
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .margin({
                    top: 6,
                    left: 12,
                    right: 12
                  })
                  .onClick(async () => {
                    await openLink(this.context, 'https://docs.qq.com/doc/p/2fc9d7d60e5b79dcc09dec8251cb049fb29c7705')
                  })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
        }
        ListItem() {
          Column() {
            Text('数据')
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
                Text('设备间同步')
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
                  .backgroundColor(this.hoverId === 5 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 5
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Tablesync'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('导入与导出')
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
                  .backgroundColor(this.hoverId === 6 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 6
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'DataInOut'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('备份与恢复')
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
                  .backgroundColor(this.hoverId === 7 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 7
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'DataBackupRecovery'
                })
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('数据防丢失指南')
              .fontColor($r('sys.color.font_emphasize'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
              .onClick(async () => {
                await openLink(this.context, 'https://docs.qq.com/doc/p/4168ccb976b6c8825e574cee297388cb431b6383')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Row() {
              Text('密钥')
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
                .backgroundColor(this.hoverId === 8 ? $r('sys.color.interactive_hover') :
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
                this.hoverId = 8
              }
            })
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Key'
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('通用')
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
                Text('通用')
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
                  .backgroundColor(this.hoverId === 9 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 9
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Commonsetting'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('卡片')
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
                  .backgroundColor(this.hoverId === 10 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 10
                }
              })
              .onClick(() => {
                formProvider.openFormManager({
                  bundleName: 'com.zhangxm.aitodo'
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

        ListItem() {
          Column() {
            Row() {
              Text('消息通知')
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
                .backgroundColor(this.hoverId === 11 ? $r('sys.color.interactive_hover') :
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
                this.hoverId = 11
              }
            })
            .onClick(() => {
              this.context.eventHub.emit('notice')
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('数据与隐私')
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
                Text('权限管理')
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
                  .backgroundColor(this.hoverId === 12 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 12
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Permissionsetting'
                })
              })

              if (typeof (this.agreedPrivacyAgreement) === 'number') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
              }
              if (this.agreedPrivacyAgreement === 0 || this.agreedPrivacyAgreement === 2) {
                Row() {
                  Text('阅读并签署隐私协议')
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
                    .backgroundColor(this.hoverId === 13 ? $r('sys.color.interactive_hover') :
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
                    this.hoverId = 13
                  }
                })
                .onClick(async () => {
                  await privacyManager.requestAppPrivacyConsent(this.context)
                  await this.getSetting()
                })
              }
              if (this.agreedPrivacyAgreement === 1) {
                Row() {
                  Text('撤回同意隐私协议')
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
                    .backgroundColor(this.hoverId === 14 ? $r('sys.color.interactive_hover') :
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
                    this.hoverId = 14
                  }
                })
                .onClick(async () => {
                  privacyManager.disableService()
                  await this.context.terminateSelf()
                })
              }
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
            Text('了解我们如何使用您的数据')
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
                Text('业务与隐私的声明')
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
                  .backgroundColor(this.hoverId === 15 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 15
                }
              })
              .onClick(async () => {
                try {
                  const appPrivacyLink = privacyManager.getAppPrivacyMgmtInfo().privacyInfo
                    .find(item => item.type === privacyManager.AppPrivacyLinkType.PRIVACY_STATEMENT_LINK)
                  this.pageInfos.pushPath({
                    name: 'Webview',
                    param: appPrivacyLink?.url
                  })
                } catch (err) {
                  await promptAction.openToast({
                    message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('第三方SDK列表')
                  .enableAutoSpacing(true)
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
                  .backgroundColor(this.hoverId === 16 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 16
                }
              })
              .onClick(async () => {
                await openLink(this.context, 'https://docs.qq.com/doc/p/3b6bf8989d6efd7ded801cf66656ae34e70163c7')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('已收集个人信息清单')
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
                  .backgroundColor(this.hoverId === 17 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 17
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Infolist'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('隐私声明摘要')
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
                  .backgroundColor(this.hoverId === 18 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 18
                }
              })
              .onClick(async () => {
                await openLink(this.context, 'https://docs.qq.com/doc/p/5fd1ebd0a7367185acd0d6e7ebee03e06bcf11f7')
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
            Text('更多')
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
                Text('应用服务模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.allService ? '全量模式' : '基本模式')
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
                  .backgroundColor(this.hoverId === 19 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 19
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Servicemode'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('其他')
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
                  .backgroundColor(this.hoverId === 20 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 20
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Moresetting'
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

        ListItem() {
          Column() {
            Row() {
              Text('关于')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text('版本 ')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
              Text($r('app.string.app_version'))
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
                .backgroundColor(this.hoverId === 21 ? $r('sys.color.interactive_hover') :
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
                this.hoverId = 21
              }
            })
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'About'
              })
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('服务协议与规则')
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
                .backgroundColor(this.hoverId === 22 ? $r('sys.color.interactive_hover') :
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
                this.hoverId = 22
              }
            })
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Agreements'
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
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
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
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
          mainTitle: '设置'
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MODAL)
    .onAppear(async () => {
      this.context.eventHub.on('refreshSetting', async () => {
        await this.getSetting()
      })
      await this.getSetting()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshSetting')
    })
  }
}