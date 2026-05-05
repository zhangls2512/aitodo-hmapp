import { common } from '@kit.AbilityKit'
import { LoadingDialog } from '@kit.ArkUI'
import { completeTodo } from '../common/Datachange'
import { getRecommendTodoList, Todo } from '../common/Dataget'
import { checkPermission } from '../common/Permission'
import { getPreferType } from '../common/Prefertype'
import { getDateTimeStringFromTimeStamp } from '../common/Stringformat'
import TodoInfo from './Todoinfo'

@ComponentV2
export default struct Recommendtodo {
  @Local isShowInfoSheet: boolean = false
  @Local preferType: number = 1
  @Local todoArray: Todo[] = []
  @Local loading: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  todoId = ''
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  getDateFromTimeStamp(timeStamp: number) {
    const date = new Date(timeStamp)
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0)
  }

  @Builder
  MenuBuilder(item: Todo) {
    Menu() {
      MenuItem({
        startIcon: $r('app.media.info'),
        content: '详情'
      })
        .onClick(() => {
          this.todoId = item.id
          this.isShowInfoSheet = true
        })
    }
  }

  @Builder
  InfoSheetBuilder(id: string) {
    TodoInfo({
      todoId: id
    })
  }

  build() {
    Refresh({
      refreshing: $$this.loading
    }) {
      List() {
        ForEach(this.todoArray, (item: Todo, index) => {
          ListItem() {
            Column() {
              Row() {
                Toggle({
                  type: ToggleType.Checkbox,
                  isOn: item.isCompleted
                })
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onChange(async (isOn) => {
                    if (!item.teamId) {
                      await completeTodo(this.context, item.id, isOn)
                    }
                    if (item.teamId) {
                      //请求团队完成待办API
                    }
                    this.loading = true
                  })
                Column() {
                  if (!item.isCompleted) {
                    Text(item.content)
                      .enableAutoSpacing(true)
                      .fontWeight(FontWeight.Bold)
                  }
                  if (item.isCompleted) {
                    Text(item.content)
                      .decoration({
                        type: TextDecorationType.LineThrough,
                        color: $r('sys.color.font_tertiary')
                      })
                      .enableAutoSpacing(true)
                      .fontColor($r('sys.color.font_tertiary'))
                      .fontWeight(FontWeight.Bold)
                  }
                  Row() {
                    Text('开始时间')
                      .fontWeight(FontWeight.Medium)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Text(getDateTimeStringFromTimeStamp(item.startTime))
                      .enableAutoSpacing(true)
                      .layoutWeight(1)
                  }
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })

                  if (item.endTime !== -1) {
                    Row() {
                      Text('结束时间')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(getDateTimeStringFromTimeStamp(item.endTime))
                        .enableAutoSpacing(true)
                        .layoutWeight(1)
                    }
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  }
                  if (item.location.location) {
                    Row() {
                      Text('地点')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.location.location)
                        .enableAutoSpacing(true)
                        .layoutWeight(1)
                    }
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  }
                  if (item.tag.length > 0) {
                    Row() {
                      Text('标签')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.tag.join('、'))
                        .enableAutoSpacing(true)
                        .layoutWeight(1)
                    }
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.comp_background_primary'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.comp_background_secondary'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = -1
                }
                if (isHover) {
                  this.hoverId = index
                }
              })
              .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
              .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            }
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: index !== 0 ? $r('sys.float.ohos_id_elements_margin_vertical_m') : 0
          })
        })
        ListItem()
          .margin({
            bottom: this.preferType === 0 ? 80 : 0
          })
      }
    }
    .height('100%')
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshTodo', () => {
        this.loading = true
      })
      await checkPermission(this.context, this.UIContext, 'ohos.permission.APPROXIMATELY_LOCATION')
      await checkPermission(this.context, this.UIContext, 'ohos.permission.LOCATION')
      this.loading = true
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTodo')
    })
    .onRefreshing(async () => {
      this.todoArray = []
      this.todoArray = await getRecommendTodoList(this.context)
      this.loading = false
    })
    .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(this.todoId), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '待办详情'
      }
    })
  }
}