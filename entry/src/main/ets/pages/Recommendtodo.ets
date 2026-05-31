import { common } from '@kit.AbilityKit'
import { LoadingDialog } from '@kit.ArkUI'
import { formProvider } from '@kit.FormKit'
import { notificationManager } from '@kit.NotificationKit'
import { completeTodo } from '../common/Datachange'
import { getRecommendTodoList, Todo } from '../common/Dataget'
import { checkPermission } from '../common/Permission'
import { getFlushPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import { getDateTimeStringFromTimeStamp } from '../common/Stringformat'
import NewTodo from './Newtodo'
import TodoInfo from './Todoinfo'

@ComponentV2
export default struct Recommendtodo {
  @Provider() isShowNewSheet: boolean = false
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
  NewSheetBuilder() {
    NewTodo({
      teamId: ''
    })
  }

  @Builder
  InfoSheetBuilder() {
    TodoInfo({
      todoId: this.todoId,
      teamId: ''
    })
  }

  build() {
    Scroll() {
      Column() {
        if (this.todoArray.length === 0 && !this.loading) {
          Text('无数据')
        }
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
                          this.dialogControllerProgress.open()
                          await completeTodo(this.context, item.id, isOn)
                          this.dialogControllerProgress.close()
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
              .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                title: {
                  title: '新增待办'
                },
                onDisappear: () => {
                  this.loading = true
                },
                onWillDismiss: async (DismissSheetAction) => {
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '数据尚未保存，确定退出？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    DismissSheetAction.dismiss()
                  }
                }
              })
          }
          .lanes({
            fillType: PresetFillType.BREAKPOINT_DEFAULT
          }, $r('sys.float.ohos_id_elements_margin_horizontal_m'))
        }
        .keyboardShortcut('R', [ModifierKey.CTRL], () => {
          this.loading = true
        })
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.todoArray = []
          this.todoArray = await getRecommendTodoList(this.context)
          if (notificationManager.isNotificationEnabledSync()) {
            const showCanCompletedTodoCountInBadge =
              getFlushPreference(this.context, 'commonSetting', 'showCanCompletedTodoCountInBadge', false)
            if (!showCanCompletedTodoCountInBadge) {
              await notificationManager.setBadgeNumber(0)
            }
            if (showCanCompletedTodoCountInBadge) {
              await notificationManager.setBadgeNumber(this.todoArray.length)
            }
          }
          await formProvider.reloadForms(this.context, 'entry', 'EntryFormAbility', 'recommendtodo')
          await formProvider.reloadForms(this.context, 'entry', 'EntryFormAbility', 'standbyrecommendtodo')
          this.loading = false
        })

        Text('推荐算法逻辑说明')
          .fontColor($r('sys.color.font_emphasize'))
          .fontSize($r('sys.float.ohos_id_text_size_body3'))
          .margin({
            bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
            await promptAction.showDialog({
              title: '推荐算法逻辑说明',
              message: '先过滤出可完成的待办，再根据当前位置与地点之间的距离、结束时间、预计耗时、优先级、标签等对其进行排序。全程离线不联网。',
              buttons: [
                {
                  text: '确定',
                  color: $r('sys.color.font_emphasize')
                }
              ]
            })
          })
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('newTodo', () => {
        if (!this.isShowNewSheet && !this.isShowInfoSheet) {
          this.isShowNewSheet = true
        }
      })
      this.context.eventHub.on('refreshTodo', () => {
        this.loading = true
      })
      this.context.eventHub.on('todoInfo', (todoId: string) => {
        if (this.isShowInfoSheet) {
          this.isShowInfoSheet = false
        }
        this.todoId = todoId
        setTimeout(() => {
          this.isShowInfoSheet = true
        }, 100)
      })
      await checkPermission(this.context, this.UIContext, 'ohos.permission.APPROXIMATELY_LOCATION')
      await checkPermission(this.context, this.UIContext, 'ohos.permission.LOCATION')
      this.loading = true
    })
    .onDisAppear(() => {
      this.context.eventHub.off('todoInfo')
      this.context.eventHub.off('refreshTodo')
      this.context.eventHub.off('newTodo')
    })
    .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '待办详情'
      }
    })
  }
}