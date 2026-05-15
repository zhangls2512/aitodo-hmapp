import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { picker } from '@kit.CoreFileKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getKeyAlg, removeKey, importRandomKey, exportKey, importCustomKey } from '../common/Crypto'
import { readUri, writeUri } from '../common/File'

@Builder
export function KeyBuilder() {
  Keypage()
}

@ComponentV2
struct Keypage {
  @Local keyAlg: string = ''
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
        if (this.keyAlg) {
          ListItem() {
            Column() {
              Row() {
                Text('密钥算法')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.keyAlg)
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
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('导入')
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
                let confirm = false
                const promptAction = this.UIContext.getPromptAction()
                if (!this.keyAlg) {
                  confirm = true
                }
                if (this.keyAlg) {
                  const res = await promptAction.showDialog({
                    title: '提示',
                    message: '导入成功后新密钥将覆盖当前密钥，当前密钥无法恢复，需重新导入当前密钥才可解密使用当前密钥加密的数据，确定导入？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '导入',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  if (res.index === 1) {
                    confirm = true
                  }
                }
                if (confirm) {
                  const data = await promptAction.showActionMenu({
                    title: '选择导入方式',
                    buttons: [
                      {
                        text: '随机 (AES256)',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '随机 (SM4)',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '自定义 (2.0.8.8 及之后版本导出的)',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '自定义 (2.0.8.8 之前版本复制的)',
                        color: $r('sys.color.font_primary')
                      }
                    ]
                  })
                  if (data.index === 0) {
                    await importRandomKey('AES256')
                  }
                  if (data.index === 1) {
                    await importRandomKey('SM4')
                  }
                  if (data.index === 2) {
                    const documentSelectOptions = new picker.DocumentSelectOptions()
                    documentSelectOptions.maxSelectNumber = 1
                    documentSelectOptions.fileSuffixFilters = ['.txt']
                    const documentViewPicker = new picker.DocumentViewPicker(this.context)
                    const uris = await documentViewPicker.select(documentSelectOptions)
                    if (uris.length === 1) {
                      const filePath = uris[0]
                      const filestring = await readUri(filePath)
                      await importCustomKey(filestring)
                    }
                  }
                  this.keyAlg = getKeyAlg()
                  if (data.index === 3) {
                    this.pageInfos.pushPath({
                      name: 'Importkey'
                    })
                  }
                }
              })

              if (this.keyAlg) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('加密导出')
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
                .onClick(async () => {
                  const documentSaveOptions = new picker.DocumentSaveOptions()
                  documentSaveOptions.newFileNames = ['todokey']
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    const key = await exportKey()
                    if (key !== 'fail') {
                      await writeUri(filePath, JSON.stringify(key))
                      await promptAction.openToast({
                        message: '导出成功'
                      })
                    }
                  }
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('删除')
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
                .onClick(async () => {
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '删除成功后无法恢复，需重新导入此密钥才可解密使用此密钥加密的数据，确定删除？',
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
                    await removeKey()
                    this.keyAlg = getKeyAlg()
                  }
                })
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('因系统密钥管理服务安全模型限制，加密导出的密钥文件仅可导入本设备上的本应用中，不支持跨设备、跨应用导入。')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
          mainTitle: '密钥'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
      this.keyAlg = getKeyAlg()
    })
  }
}