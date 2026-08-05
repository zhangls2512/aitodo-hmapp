import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getTagList, setTag, Tag } from '../common/Tag'

@Builder
export function TagBuilder() {
  TagPage()
}

@ComponentV2
struct TagPage {
  @Local tagArray: Tag[] = []
  @Local tag: string = ''
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
          Text('标签兴趣度影响待办推荐顺序。9最感兴趣，1最不感兴趣，未设置、5中等感兴趣。')
            .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            TextInput({
              placeholder: '请输入标签',
              text: this.tag!!
            })
              .enableAutoSpacing(true)
            Button('添加')
              .enabled(this.tag !== '' ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                if (this.tagArray.find(item => item.value === this.tag)) {
                  await promptAction.openToast({
                    message: '标签已存在'
                  })
                  return
                }
                this.tagArray.push({
                  value: this.tag,
                  priority: 5
                })
                await setTag(this.context, this.tagArray)
                this.tag = ''
              })
          }
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ForEach(this.tagArray, (item: Tag, index) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.value)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Counter() {
                  Text(String(item.priority))
                }
                .enableDec(item.priority > 1)
                .enableInc(item.priority < 9)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onInc(async () => {
                  const temp = [...this.tagArray]
                  temp[index].priority++
                  this.tagArray = temp
                  await setTag(this.context, this.tagArray)
                })
                .onDec(async () => {
                  const temp = [...this.tagArray]
                  temp[index].priority--
                  this.tagArray = temp
                  await setTag(this.context, this.tagArray)
                })

                Image($r('app.media.delete'))
                  .height(24)
                  .onClick(async () => {
                    const promptAction = this.UIContext.getPromptAction()
                    const data = await promptAction.showDialog({
                      title: '提示',
                      message: '删除成功后无法恢复，确定删除？',
                      buttons: [
                        {
                          text: '取消',
                          color: $r('sys.color.font_primary')
                        },
                        {
                          text: '删除',
                          color: $r('sys.color.warning')
                        }
                      ]
                    })
                    if (data.index === 1) {
                      this.tagArray.splice(index, 1)
                      await setTag(this.context, this.tagArray)
                    }
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
          mainTitle: '标签兴趣度'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      this.tagArray = await getTagList(this.context)
    })
  }
}