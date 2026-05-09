import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { cancelProxyReminder, getProxyReminderList, ProxyReminder } from '../common/Proxyreminder'
import { getDateTimeStringFromTimeStamp } from '../common/Stringformat'

@Builder
export function RemindBuilder() {
  Remind()
}

@ComponentV2
struct Remind {
  @Local remindArray: ProxyReminder[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  async get() {
    this.remindArray = await getProxyReminderList()
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.remindArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.remindArray, (item: ProxyReminder) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text(getDateTimeStringFromTimeStamp(item.time))
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                  Text('待办ID：' + item.todoId)
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                  Text('标题：' + item.title)
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                  if (item.content) {
                    Text('内容：' + item.content)
                      .enableAutoSpacing(true)
                      .fontColor($r('sys.color.font_secondary'))
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

                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(async () => {
                    await cancelProxyReminder(item.todoId)
                    await this.get()
                  })
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
          mainTitle: '提醒管理'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      await this.get()
    })
  }
}