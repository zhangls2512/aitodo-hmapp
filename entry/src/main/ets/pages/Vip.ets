import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken, getPersonalAccountInfo } from '../common/Account'
import openLink from '../common/Openlink'
import { developerRequest } from '../common/Request'

export interface VipItem {
  id: string,
  name: string,
  type: iap.ProductType,
  price: string
}

@ComponentV2
export default struct Vip {
  @Local vipStatusLoading: boolean = false
  @Local backupMaxCount: number = -1
  @Local iapStatus: boolean = false
  @Local iapStatusLoading: boolean = false
  @Local agree: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  accessToken = ''
  uid = ''
  vipArray: VipItem[] = [
    {
      id: 'iqKBj_k_muJcd3yc',
      name: '20个永久云备份空间',
      type: iap.ProductType.CONSUMABLE,
      price: '￥5'
    }
  ]

  async getVipStatus() {
    this.vipStatusLoading = true
    const userres = await developerRequest(this.context, '/product/getUserInfo', {
      accessToken: this.accessToken,
      product: 'todo'
    })
    this.vipStatusLoading = false
    if (userres !== 'fail') {
      this.backupMaxCount = JSON.parse(userres).data.backupMaxCount as number
    }
  }

  async buyVip(id: string, type: iap.ProductType) {
    if (!this.agree) {
      await promptAction.openToast({
        message: '请阅读并同意服务协议'
      })
      return
    }
    netBoost.setSceneDesc({
      scene: 'transaction',
      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
    })
    try {
      await iap.createPurchase(this.context, {
        productId: id,
        productType: type,
        developerPayload: this.uid
      })
      netBoost.setSceneDesc({
        scene: 'transaction',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
      })
      await promptAction.openToast({
        message: '服务器正在验证，大约需要 5-20 秒，请稍候'
      })
    } catch (err) {
      netBoost.setSceneDesc({
        scene: 'transaction',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
      })
      if (err.code === 1001860004) {
        await promptAction.openToast({
          message: '操作过于频繁，请稍后再试'
        })
      }
      if (err.code === 1001860051) {
        await promptAction.openToast({
          message: '您已购买，不能重复购买'
        })
      }
      if (err.code !== 1001860000 && err.code !== 1001860005 && err.code !== 1001860004 && err.code !== 1001860051) {
        await promptAction.openToast({
          message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
        })
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
        ListItem() {
          Column() {
            if (!this.vipStatusLoading) {
              Text('永久云备份空间：' + this.backupMaxCount + '个')
                .enableAutoSpacing(true)
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
            }
            if (this.vipStatusLoading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.iapStatusLoading) {
          ListItem() {
            LoadingProgress()
              .width('20%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
        if (this.iapStatus) {
          ListItem() {
            Column() {
              Text('付费开通')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: 6,
                  left: 12,
                  right: 12
                })
              Column() {
                Column() {
                  ForEach(this.vipArray, (item: VipItem, index) => {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(item.name)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.price)
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
                        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                      },
                      hovered: {
                        .backgroundColor($r('sys.color.interactive_hover'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .onClick(async () => {
                      await this.buyVip(item.id, item.type)
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Row() {
                  Toggle({
                    type: ToggleType.Checkbox,
                    isOn: this.agree!!
                  })
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text() {
                    Span('已阅读并同意')
                    Span('《轩铭智能待办会员服务协议》')
                      .fontColor($r('sys.color.font_emphasize'))
                      .onClick(async () => {
                        await openLink(this.context,
                          'https://docs.qq.com/doc/p/c92238f5bc762eb8495ed60ef45c36c5ddebd573')
                      })
                    Span('。')
                  }
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .layoutWeight(1)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
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
                Text('邀请新用户，免费得会员')
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
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Invite'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('兑换码')
                  .fontColor(Color.Red)
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
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Vipcode'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('开通记录')
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
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Viplog'
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
          mainTitle: '会员中心'
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MODAL)
    .onAppear(async () => {
      this.accessToken = await getPersonalAccountAccessToken()
      if (this.accessToken) {
        const accountInfo = await getPersonalAccountInfo()
        this.uid = accountInfo.uid
        this.context.eventHub.on('refreshVip', async () => {
          await this.getVipStatus()
        })
        await this.getVipStatus()
        this.iapStatusLoading = true
        try {
          await iap.queryEnvironmentStatus(this.context)
          this.iapStatusLoading = false
          this.iapStatus = true
        } catch (err) {
          this.iapStatusLoading = false
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
          })
        }
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshVip')
    })
  }
}