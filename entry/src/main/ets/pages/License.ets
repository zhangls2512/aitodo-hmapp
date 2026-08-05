import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import openLink from '../common/Openlink'

interface ItemWithDesc {
  key: string,
  value: string,
  desc: string
}

@Builder
export function LicenseBuilder() {
  License()
}

@ComponentV2
struct License {
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  tscjbaInfoArray: ItemWithDesc[] = [
    {
      key: '适老化',
      value: '轩铭2512适备13号-1L',
      desc: '字体跟随系统关怀模式设置放大'
    },
    {
      key: '无障碍',
      value: '轩铭2512适备13号-2Z',
      desc: '尽可能多地使用系统组件、API，以最大化地利用系统内置的无障碍特性'
    },
    {
      key: '大小屏',
      value: '轩铭2512适备13号-3P',
      desc: '适配平板、PC 大屏'
    },
    {
      key: '特殊网络环境',
      value: '轩铭2512适备13号-4W',
      desc: '无网环境使用在线功能时弹窗提示'
    },
    {
      key: '深色模式',
      value: '轩铭2512适备13号-5S',
      desc: '界面跟随“我的”>“设置”>“通用”>“通用”>“界面”>“深色模式”设置改变颜色主题'
    }
  ]

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Text() {
            Span('ICP备案：')
            Span('黑ICP备2024023054号-7A')
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(async () => {
                await openLink(this.context, 'https://beian.miit.gov.cn/#/Integrated/recordQuery')
              })
          }
          .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Text() {
            Span('产品备案：')
            Span('轩铭2512品备13号-HA')
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(async () => {
                await openLink(this.context,
                  'https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512品备13号-HA')
              })
          }
          .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('特殊场景适配备案')
              .fontWeight(FontWeight.Bold)
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              Column() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('备案号')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              ForEach(this.tscjbaInfoArray, (item: ItemWithDesc) => {
                Column() {
                  Text(item.key)
                    .fontColor($r('sys.color.font_emphasize'))
                    .textAlign(TextAlign.Center)
                    .onClick(async () => {
                      const promptAction = this.UIContext.getPromptAction()
                      await promptAction.showDialog({
                        title: '描述',
                        message: item.desc,
                        buttons: [
                          {
                            text: '确定',
                            color: $r('sys.color.font_emphasize')
                          }
                        ]
                      })
                    })
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    right: 1,
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')

                Column() {
                  Text(item.value)
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_emphasize'))
                    .textAlign(TextAlign.Center)
                    .onClick(async () => {
                      await openLink(this.context,
                        'https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=' + item.value)
                    })
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')
              })
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('隐私安全备案')
              .fontWeight(FontWeight.Bold)
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              Column() {
                Text('描述')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('备案号')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text(
                  '有隐私相关功能，包括但不限于权限管理、业务与隐私的声明、第三方SDK列表、已收集个人信息清单、隐私声明摘要')
                  .enableAutoSpacing(true)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('轩铭2512私安备13号-1')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_emphasize'))
                  .textAlign(TextAlign.Center)
                  .onClick(async () => {
                    await openLink(this.context,
                      'https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512私安备13号-1')
                  })
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
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
          mainTitle: '资质证照'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
  }
}