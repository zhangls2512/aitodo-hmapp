import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getTeamAccountList, removeAccount, TeamAccountInfo } from '../common/Account'

@ComponentV2
export default struct Team {
  @Local teamAccountArray: TeamAccountInfo[] = []
  @Local hoverId: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    HdsNavigation(this.pageInfos) {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Button('登录新账号')
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Loginteamaccount'
              })
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.teamAccountArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.teamAccountArray, (item: TeamAccountInfo, index) => {
          ListItem() {
            Column() {
              Text(item.teamName)
                .enableAutoSpacing(true)
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
                  Text(item.name)
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('账号信息')
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
                    this.hoverId = ''
                  }
                  if (isHover) {
                    this.hoverId = '0,' + index
                  }
                })
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'Teamaccountinfo',
                    param: item.teamId
                  })
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('修改密码')
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
                    this.hoverId = ''
                  }
                  if (isHover) {
                    this.hoverId = '1,' + index
                  }
                })
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'Updateteamaccountpassword',
                    param: item.teamId
                  })
                })

                if (item.admin === 'true') {
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('团队信息')
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
                      this.hoverId = ''
                    }
                    if (isHover) {
                      this.hoverId = '2,' + index
                    }
                  })
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Teaminfo',
                      param: item.teamId
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('用户管理')
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
                      this.hoverId = ''
                    }
                    if (isHover) {
                      this.hoverId = '3,' + index
                    }
                  })
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Teamaccountlist',
                      param: item.teamId
                    })
                  })
                }
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('退出')
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
                    .backgroundColor(this.hoverId === '4,' + index ? $r('sys.color.interactive_hover') :
                      $r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .onHover(isHover => {
                  if (!isHover) {
                    this.hoverId = ''
                  }
                  if (isHover) {
                    this.hoverId = '4,' + index
                  }
                })
                .onClick(async () => {
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '确定退出？',
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
                  if (data.index === 1) {
                    await removeAccount(item.id)
                    await promptAction.openToast({
                      message: '退出成功'
                    })
                    this.teamAccountArray = await getTeamAccountList()
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
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
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
          mainTitle: '团队'
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MODAL)
    .onAppear(async () => {
      this.context.eventHub.on('refreshTeam', async () => {
        this.teamAccountArray = await getTeamAccountList()
      })
      this.teamAccountArray = await getTeamAccountList()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTeam')
    })
  }
}