import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getTeamAccountInfo, removeAccount } from '../common/Account'
import openLink from '../common/Openlink'
import { teamRequest } from '../common/Request'
import { Response } from './Loginteamaccount'
import { VipItem } from './Vip'

@Builder
export function TeaminfoBuilder() {
  Teaminfo()
}

@ComponentV2
struct Teaminfo {
  @Local teamId: string = ''
  @Local teamName: string = ''
  @Local userCount: number = -1
  @Local todoCount: number = -1
  @Local userMaxCount: string = ''
  @Local todoMaxCount: string = ''
  @Local iapStatus: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  agree = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
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
              Text('ID')
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
              Text('名')
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
              Text('用户')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userCount + '/' + this.userMaxCount)
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
              Text('待办')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.todoCount + '/' + this.todoMaxCount)
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
            Row() {
              Text('付费开通记录')
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
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Teamviplog',
                param: this.teamId
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
          Button('注销团队')
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              const data = await promptAction.showDialog({
                title: '提示',
                message: '注销成功后无法恢复，确定注销？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '注销',
                    color: $r('sys.color.warning')
                  }
                ]
              })
              if (data.index === 1) {
                this.dialogControllerProgress.open()
                const res = await teamRequest(this.context, this.teamId, '/deleteTeam')
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  const teamAccountInfo = await getTeamAccountInfo(this.teamId)
                  await removeAccount(teamAccountInfo.id)
                  await promptAction.openToast({
                    message: '注销成功'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshTeam')
                }
              }
            })
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
          mainTitle: '团队信息'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.teamId = context.pathInfo.param as string
      this.dialogControllerProgress.open()
      const res = await teamRequest(this.context, this.teamId, '/getTeamInfo')
      this.dialogControllerProgress.close()
      if (res !== 'fail') {
        const response = JSON.parse(res) as Response
        this.teamName = response.data.teamName
        this.userCount = response.data.userCount
        this.todoCount = response.data.todoCount
        this.userMaxCount = response.data.userMaxCount ? String(response.data.userMaxCount) : '∞'
        this.todoMaxCount = response.data.todoMaxCount ? String(response.data.todoMaxCount) : '∞'
        try {
          await iap.queryEnvironmentStatus(this.context)
          this.iapStatus = true
        } catch (err) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      }
    })
  }
}