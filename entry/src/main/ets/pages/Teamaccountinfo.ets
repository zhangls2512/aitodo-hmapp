import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import openLink from '../common/Openlink'
import { teamRequest } from '../common/Request'
import { Response } from './Loginteamaccount'
import { VipItem } from './Vip'

@Builder
export function TeamaccountinfoBuilder() {
  Teamaccountinfo()
}

@ComponentV2
struct Teamaccountinfo {
  @Local teamId: string = ''
  @Local teamName: string = ''
  @Local userMaxCount: string = ''
  @Local todoMaxCount: string = ''
  @Local userId: string = ''
  @Local userName: string = ''
  @Local admin: boolean = false
  @Local permission: string = ''
  @Local iapStatus: boolean = false
  @Local hoverId: number = -1
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  agree = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  permissionMap: Record<string, string> = {
    'newTodo': '新增待办',
    'getTodo': '查看待办'
  }
  vipArray: VipItem[] = [
    {
      id: 'XBCGwpIuyeAPvuk2',
      name: '4个账号、20个待办',
      type: iap.ProductType.CONSUMABLE,
      price: '￥5'
    }
  ]

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
        developerPayload: this.teamId
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
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    }
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
            Row() {
              Text('团队ID')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.teamId)
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
              Text('团队名')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.teamName)
                .enableAutoSpacing(true)
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
              Text('团队用户数上限')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userMaxCount)
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
              Text('团队待办数上限')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.todoMaxCount)
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
              Text('用户ID')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userId)
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
              Text('用户名')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userName)
                .enableAutoSpacing(true)
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
              Text('管理员')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.admin ? '是' : '否')
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
              Text('权限')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.permission ? this.permission : '无')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.admin && this.iapStatus) {
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
                        .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
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
                        this.hoverId = index
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
          mainTitle: '账号信息'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.teamId = context.pathInfo.param as string
      this.dialogControllerProgress.open()
      const res = await teamRequest(this.context, this.teamId, '/getUserInfo')
      this.dialogControllerProgress.close()
      if (res !== 'fail') {
        const response = JSON.parse(res) as Response
        this.teamName = response.data.teamName
        this.userMaxCount = response.data.userMaxCount ? String(response.data.userMaxCount) : '-'
        this.todoMaxCount = response.data.todoMaxCount ? String(response.data.todoMaxCount) : '-'
        this.userId = response.data.userId
        this.userName = response.data.userName
        this.admin = response.data.admin
        this.permission = response.data.permission.map(item => this.permissionMap[item]).join('、')
        if (this.admin) {
          try {
            await iap.queryEnvironmentStatus(this.context)
            this.iapStatus = true
          } catch (err) {
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
            })
          }
        }
      }
    })
  }
}