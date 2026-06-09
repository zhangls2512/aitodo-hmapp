import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { deleteIndex, deleteRdbStoreData, getAllData } from '../common/Rdbstore'

@Builder
export function RdbstoreBuilder() {
  Rdbstore()
}

@ComponentV2
struct Rdbstore {
  @Local dataArray: string[][][] = []
  @Local indexArray: string [][][] = []
  @Local hoverId: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  storeName = 'todo'

  async refreshIndex() {
    this.indexArray = []
    const indexArray = await getAllData(this.context, this.storeName, 'sqlite_master')
    this.indexArray = indexArray.filter(item => item[0][1] === 'index' && !item[1][1].startsWith('sqlite_'))
  }

  async refreshData() {
    this.dataArray = []
    this.dataArray = await getAllData(this.context, this.storeName, 'todo')
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          Select([
            { value: 'todo' },
            { value: 'huaweicloudsync' }
          ])
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .selected(0)
            .value('todo')
            .onSelect(async (index) => {
              this.storeName = ['todo', 'huaweicloudsync'][index]
              await this.refreshIndex()
              await this.refreshData()
            })
          List() {
            ListItem() {
              Text('索引')
                .fontWeight(FontWeight.Medium)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })

            if (this.indexArray.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.indexArray, (item: string[][], index) => {
              ListItem() {
                Column() {
                  ForEach(item, (inItem: string[], inIndex) => {
                    if (inIndex !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(inItem[0])
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(inItem[1])
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
                    }
                    .borderRadius(12)
                    .padding(12)
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
                  .onClick(async () => {
                    const promptAction = this.UIContext.getPromptAction()
                    const data = await promptAction.showDialog({
                      title: '提示',
                      message: '删除成功后会降低查询效率，确定删除？',
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
                      await deleteIndex(this.context, this.storeName, item[1][1])
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      await this.refreshIndex()
                    }
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            })
            ListItem() {
              Text('数据')
                .fontWeight(FontWeight.Medium)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })

            if (this.dataArray.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.dataArray, (item: string[][], index) => {
              ListItem() {
                Column() {
                  ForEach(item, (inItem: string[], inIndex) => {
                    if (inIndex !== 0) {
                      Divider()
                        .padding({
                          left: 12,
                          right: 12
                        })
                    }
                    Row() {
                      Text(inItem[0])
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(inItem[1])
                        .enableAutoSpacing(true)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
                    }
                    .borderRadius(12)
                    .padding(12)
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
                      await deleteRdbStoreData(this.context, this.storeName, 'todo', 'id', item[0][1])
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      await this.refreshData()
                    }
                  })
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
          .layoutWeight(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({
          top: 64
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
          mainTitle: '关系型数据库'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      await this.refreshIndex()
      await this.refreshData()
    })
  }
}