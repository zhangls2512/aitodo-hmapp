import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getCustomFreqFromName, setCustomFreq, YMD } from '../common/Customfreq'

@Builder
export function CustomfreqeditBuilder() {
  Customfreqedit()
}

@ComponentV2
struct Customfreqedit {
  @Local name: string = ''
  @Local list: YMD[] = []
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Button('添加')
            .width('100%')
            .onClick(() => {
              this.UIContext.showDatePickerDialog({
                onDateAccept: async (value) => {
                  const year = value.getFullYear()
                  const month = value.getMonth() + 1
                  const day = value.getDate()
                  if (this.list.find(item => item.year === year && item.month === month && item.day === day)) {
                    await promptAction.openToast({
                      message: '日期已存在'
                    })
                    return
                  }
                  this.list.push({
                    year: year,
                    month: month,
                    day: day
                  })
                  setCustomFreq(this.context, this.name, this.list)
                }
              })
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.list, (item: YMD, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.year + '年' + item.month + '月' + item.day + '日')
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(() => {
                    this.list.splice(index, 1)
                    setCustomFreq(this.context, this.name, this.list)
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
          mainTitle: '修改' + this.name
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.name = context.pathInfo.param as string
      this.list = getCustomFreqFromName(this.context, this.name)
    })
  }
}