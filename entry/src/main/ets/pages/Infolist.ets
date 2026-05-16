import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { pushService } from '@kit.PushKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken } from '../common/Account'
import getDeviceToken from '../common/Devicetoken'
import openLink from '../common/Openlink'

@Builder
export function InfolistBuilder() {
  Infolist()
}

@ComponentV2
struct Infolist {
  @Local accessToken: string = ''
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Text(
            '张轩铭 (以下简称我) 会严格遵从国家的法规要求，将合法合规融入产品设计和业务流程中，并采用业界先进的安全技术保证数据安全。\n在新的服务需求及业务功能变更时，我可能会调整我收集信息的范围，并及时在本说明中向您说明情况。')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          left: 12,
          right: 12,
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('IP地址及其归属地、运营商')
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
              Column() {
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('查询轩铭2512统一账号登录日志时')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('生成、存储轩铭2512统一账号登录日志')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('轩铭2512统一账号登录成功时')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('服务器自动删除距今超过30天的')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('信息内容')
                    .fontWeight(FontWeight.Medium)
                  Text('https://www.zhangls2512.cn/product/account/loginlog')
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
                await openLink(this.context, 'https://www.zhangls2512.cn/product/account/loginlog')
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
            Text('华为账号UnionID')
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
              Column() {
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('华为账号登录时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('关联华为账号与轩铭2512统一账号')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('绑定华为账号时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('解绑华为账号')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('信息内容')
                    .fontWeight(FontWeight.Medium)
                  Text('https://www.zhangls2512.cn/product/account/info')
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
                await openLink(this.context, 'https://www.zhangls2512.cn/product/account/info')
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
            Text('订单号、商品ID')
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
              Column() {
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('开通会员、查询会员开通记录时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('开通会员、生成并存储会员开通记录')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('付费开通会员时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('联系客服咨询')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              if (this.accessToken) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('信息内容')
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
                .onClick(() => {
                  this.pageInfos.pushPath({
                    name: 'Viplog'
                  })
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
            Text('DeviceToken')
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
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('服务器验证邀请码时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('让服务器知晓本设备是否使用过邀请码')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('提交邀请码时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('服务器仅临时使用、不长期存储，无需删除')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('信息内容')
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
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '请求中...'
                  })
                })
                dialogControllerProgress.open()
                const deviceToken = await getDeviceToken()
                dialogControllerProgress.close()
                if (deviceToken) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: 'DeviceToken',
                    message: deviceToken,
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
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
            Text('云备份数据')
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
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('导入云备份时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('备份数据到云服务器')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('云备份时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('取消、清空云备份')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('信息内容')
                  .fontWeight(FontWeight.Medium)
                Text('数据ID、数据密文、密钥初始向量')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')
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
            Text('PushToken')
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
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('服务器推送通知时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('让服务器知晓推送通知到哪个设备')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('开启通知位时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('关闭全部通知位')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('信息内容')
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
                try {
                  const pushToken = await pushService.getToken()
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: 'PushToken',
                    message: pushToken,
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                } catch (err) {
                  await promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
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
            Text('故障日志')
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
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('开发者分析故障时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('让开发者知晓故障，以便尽快修复，保障应用稳定运行')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('发生故障时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('对应故障处理完成后、联系客服申请')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('信息内容')
                    .fontWeight(FontWeight.Medium)
                  Text('应用名称、应用版本号、故障日志、联系方式')
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
                  name: 'Errorlog'
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
            Text('意见反馈')
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
                Text('使用场景')
                  .fontWeight(FontWeight.Medium)
                Text('开发者处理意见反馈时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('使用目的')
                  .fontWeight(FontWeight.Medium)
                Text('让开发者知晓意见反馈，以处理')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('收集时机')
                  .fontWeight(FontWeight.Medium)
                Text('提交意见反馈时')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('删除时机')
                  .fontWeight(FontWeight.Medium)
                Text('意见反馈处理完成后、联系客服申请')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Column() {
                Text('信息内容')
                  .fontWeight(FontWeight.Medium)
                Text('应用名称 (智能待办)、内容、联系方式')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .borderRadius(12)
              .padding(12)
              .width('100%')
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
          mainTitle: '已收集个人信息清单'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.accessToken = await getPersonalAccountAccessToken()
    })
  }
}