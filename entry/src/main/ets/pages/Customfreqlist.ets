import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { picker } from '@kit.CoreFileKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import {
  CustomFreq,
  getCustomFreqFromName,
  getCustomFreqList,
  removeCustomFreq,
  setCustomFreq
} from '../common/Customfreq'
import { readUri, writeUri } from '../common/File'

@Builder
export function CustomfreqlistBuilder() {
  Customfreqlist()
}

@ComponentV2
struct Customfreqlist {
  @Local customFreqArray: CustomFreq[] = []
  @Local customFreqName: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  get() {
    this.customFreqArray = getCustomFreqList(this.context)
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
            TextInput({
              placeholder: '请输入自定义重复周期名称',
              text: this.customFreqName!!
            })
              .enableAutoSpacing(true)
            Button('新增')
              .enabled(this.customFreqName !== '' ? true : false)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                if ([';', 'YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY'].some(item => this.customFreqName.includes(item))) {
                  await promptAction.openToast({
                    message: '重复周期名称中含有非法字符'
                  })
                  return
                }
                if (this.customFreqArray.find(item => item.name === this.customFreqName)) {
                  await promptAction.openToast({
                    message: '重复周期名称已存在'
                  })
                  return
                }
                setCustomFreq(this.context, this.customFreqName, [])
                await promptAction.openToast({
                  message: '新增成功'
                })
                this.customFreqName = ''
                this.get()
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Button('导入')
            .width('100%')
            .onClick(async () => {
              const documentSelectOptions = new picker.DocumentSelectOptions()
              documentSelectOptions.maxSelectNumber = 1
              documentSelectOptions.fileSuffixFilters = ['.txt']
              const documentViewPicker = new picker.DocumentViewPicker(this.context)
              const uris = await documentViewPicker.select(documentSelectOptions)
              if (uris.length === 1) {
                const filePath = uris[0]
                const filestring = await readUri(filePath)
                try {
                  const customFreq = JSON.parse(filestring) as CustomFreq
                  setCustomFreq(this.context, customFreq.name, customFreq.list)
                  await promptAction.openToast({
                    message: '导入成功'
                  })
                  this.get()
                } catch {
                  await promptAction.openToast({
                    message: '导入失败'
                  })
                }
              }
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ForEach(this.customFreqArray, (item: CustomFreq) => {
          ListItem() {
            Column() {
              Row() {
                Text(item.name)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.export'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    const documentSaveOptions = new picker.DocumentSaveOptions()
                    documentSaveOptions.newFileNames = [item.name]
                    documentSaveOptions.fileSuffixChoices = ['.txt']
                    const documentViewPicker = new picker.DocumentViewPicker(this.context)
                    const uris = await documentViewPicker.save(documentSaveOptions)
                    if (uris.length === 1) {
                      const filePath = uris[0]
                      await writeUri(filePath, JSON.stringify({
                        name: item.name,
                        list: getCustomFreqFromName(this.context, item.name)
                      }))
                      await promptAction.openToast({
                        message: '导出成功'
                      })
                    }
                  })
                Image($r('app.media.edit'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Customfreqedit',
                      param: item.name
                    })
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
                      removeCustomFreq(this.context, item.name)
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      this.get()
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
          mainTitle: '自定义重复周期'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
      this.get()
    })
  }
}