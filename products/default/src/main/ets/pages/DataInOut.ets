import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalTodoList } from '../common/Dataget'
import { importTodo } from '../common/Dataimport'
import { readUri, writeUri } from '../common/File'
import { icsparse, icsstringify } from '../common/Ics'

@Builder
export function DataInOutBuilder() {
  DataInOut()
}

@ComponentV2
struct DataInOut {
  @Local index: number = 0
  @Local value: string = '保留'
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
          Column() {
            Row() {
              Text('冲突解决模式')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Select([
                { value: '保留' },
                { value: '覆盖' }
              ])
                .selected(this.index!!)
                .value(this.value!!)
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

        ListItem() {
          Column() {
            Text('导入 (支持加密备份文件)')
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
                Text('待办')
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
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const filePath = uris[0]
                  const filestring = await readUri(filePath)
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  const res = await importTodo(this.context, filestring, conflictResolution)
                  if (res === 'success') {
                    await promptAction.openToast({
                      message: '导入成功'
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
                Text('待办附件')
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
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                documentSelectOptions.fileSuffixFilters = ['.zip']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const todoExtraFileDir = this.context.filesDir + '/todoextrafile/'
                  if (!fileIo.accessSync(todoExtraFileDir)) {
                    await fileIo.mkdir(todoExtraFileDir, true)
                  }
                  const filePath = this.context.tempDir + '/todoextrafile.zip'
                  const srcFile = fileIo.openSync(uris[0])
                  const destFile = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await zlib.decompressFile(filePath, todoExtraFileDir)
                  await fileIo.unlink(filePath)
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '导入成功，需重启应用生效，是否重启？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '重启',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    const applicationContext = this.context.getApplicationContext()
                    applicationContext.restartApp({
                      bundleName: 'com.zhangxm.aitodo',
                      abilityName: 'EntryAbility'
                    })
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('导入待办须知：txt文件需为从本页面下方导出的。')
              .enableAutoSpacing(true)
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Row() {
              Text('导入第三方待办 (vcs/ics)')
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
              const documentSelectOptions = new picker.DocumentSelectOptions()
              documentSelectOptions.maxSelectNumber = 1
              documentSelectOptions.fileSuffixFilters = ['.vcs', '.ics']
              const documentViewPicker = new picker.DocumentViewPicker(this.context)
              const uris = await documentViewPicker.select(documentSelectOptions)
              if (uris.length === 1) {
                const filePath = uris[0]
                const filestring = await readUri(filePath)
                let conflictResolution = 0
                if (this.index === 1) {
                  conflictResolution = 5
                }
                await importTodo(this.context, JSON.stringify({
                  encrypted: false,
                  data: icsparse(filestring)
                }), conflictResolution)
                await promptAction.openToast({
                  message: '导入成功'
                })
              }
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
          Column() {
            Text(
              '导出 (未加密，请务必安全存储，保障数据安全。如需加密，请前往“我的”>“设置”>“数据”>“备份与恢复”>“文件”，开启“加密”，手动备份成功后导出)')
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
                Text('待办')
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
                const array = await getPersonalTodoList(this.context)
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['todo']
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '选择格式',
                  buttons: [
                    {
                      text: 'txt (完整)',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: 'ics (仅包含 ics 格式支持的字段)',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    await writeUri(filePath, JSON.stringify(array))
                    await promptAction.openToast({
                      message: '导出成功'
                    })
                  }
                }
                if (data.index === 1) {
                  documentSaveOptions.fileSuffixChoices = ['.ics']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    await writeUri(filePath, icsstringify(array))
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
                Text('待办附件')
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
                const todoExtraFileDir = this.context.filesDir + '/todoextrafile/'
                if (!fileIo.accessSync(todoExtraFileDir)) {
                  await promptAction.openToast({
                    message: '无待办附件，无需导出'
                  })
                  return
                }
                const todoExtraFileNameArray = await fileIo.listFile(todoExtraFileDir)
                const todoExtraFilePathArray = todoExtraFileNameArray.map(item => todoExtraFileDir + item)
                if (todoExtraFilePathArray.length === 0) {
                  await promptAction.openToast({
                    message: '无待办附件，无需导出'
                  })
                  return
                }
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['todoextrafile']
                documentSaveOptions.fileSuffixChoices = ['.zip']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  const filePath = this.context.tempDir + '/todoextrafile.zip'
                  await zlib.compressFiles(todoExtraFilePathArray, filePath, {})
                  const srcFile = fileIo.openSync(filePath)
                  const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await fileIo.unlink(filePath)
                  await promptAction.openToast({
                    message: '导出成功'
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
          mainTitle: '数据导入与导出'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
    })
  }
}