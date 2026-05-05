import { common } from '@kit.AbilityKit'
import { FunctionComponent } from '@kit.AgentFrameworkKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { hdsEffect } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { completeTodo, deleteCloudBackup, deleteTodo, setCloudBackup } from '../common/Datachange'
import { getCurrentTimePersonalTodoList, Todo } from '../common/Dataget'
import { getPreferType } from '../common/Prefertype'
import { deleteQuickBarTodo, getQuickBarTodoIdList, setQuickBarTodo, syncQuickBarTodo } from '../common/Quickbar'
import { getDateStringFromTimeStamp, getDateTimeStringFromTimeStamp } from '../common/Stringformat'
import NewTodo from './Newtodo'
import TodoInfo from './Todoinfo'
import UpdateTodo from './Updatetodo'

@ComponentV2
export default struct TodoPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local isShowInfoSheet: boolean = false
  @Local preferType: number = 1
  @Local todoArray: Todo[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local teamId: string = ''
  @Local currentTime: number = -1
  @Local contentKeyword: string = ''
  @Local tag: string[] = []
  @Local tags: string[] = []
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Todo[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  @Local quickBarTodoIdArray: string[] = []
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
      if (this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '取消多选'
        })
          .onClick(() => {
            this.multipleSelect = false
            this.multipleSelectArray = []
          })
      }
      if (!this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '多选'
        })
          .onClick(() => {
            this.multipleSelect = true
            this.multipleSelectArray.push(item)
          })
        if (!this.teamId && deviceInfo.deviceType === '2in1') {
          if (!this.quickBarTodoIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.addcircle'),
              content: '添加至快捷栏'
            })
              .onClick(async () => {
                await setQuickBarTodo(this.context, item.id, item.content)
                await syncQuickBarTodo(this.context)
                this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
                if (this.quickBarTodoIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '添加成功'
                  })
                }
              })
          }
          if (this.quickBarTodoIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.removecircle'),
              content: '从快捷栏移除'
            })
              .onClick(async () => {
                await deleteQuickBarTodo(this.context, item.id)
                await syncQuickBarTodo(this.context)
                this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
                if (!this.quickBarTodoIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '移除成功'
                  })
                }
              })
          }
        }
        MenuItem({
          startIcon: $r('app.media.info'),
          content: '详情'
        })
          .onClick(() => {
            this.todoId = item.id
            this.isShowInfoSheet = true
          })
        MenuItem({
          startIcon: $r('app.media.edit'),
          content: '修改'
        })
          .onClick(() => {
            this.todoId = item.id
            this.isShowUpdateSheet = true
          })
        MenuItem({
          startIcon: $r('app.media.delete'),
          content: '删除'
        })
          .onClick(async () => {
            const promptAction = this.UIContext.getPromptAction()
            if (!item.recurrenceRule) {
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
                await deleteTodo(this.context, item.id)
              }
            }
            if (item.recurrenceRule) {
              const data = await promptAction.showActionMenu({
                title: '删除模式',
                buttons: [
                  {
                    text: '仅限此待办',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '所有重复待办',
                    color: $r('sys.color.font_primary')
                  }
                ]
              })
              if (data.index === 0) {
                await deleteTodo(this.context, item.id, true, item.excludeTime.concat([item.startTime]))
              }
              if (data.index === 1) {
                await deleteTodo(this.context, item.id)
              }
            }
            this.loading = true
          })
        if (!this.teamId) {
          if (this.enableCloudBackup && !item.isCloudBackup) {
            MenuItem({
              startIcon: $r('app.media.cloud'),
              content: '云备份'
            })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                await setCloudBackup(this.context, {
                  id: item.id,
                  content: JSON.stringify({
                    content: item.content,
                    priority: item.priority,
                    startTime: item.startTime,
                    endTime: item.endTime,
                    duration: item.duration,
                    recurrenceRule: item.recurrenceRule,
                    excludeTime: item.excludeTime,
                    tag: item.tag,
                    dependency: item.dependency,
                    location: item.location,
                    action: item.action,
                    bz: item.bz,
                    recentCompletedTime: item.recentCompletedTime,
                    updateTime: item.updateTime,
                    cloudBackupTime: item.cloudBackupTime
                  })
                })
                this.dialogControllerProgress.close()
                this.loading = true
              })
          }
          if (this.enableCloudBackup && item.isCloudBackup) {
            MenuItem({
              startIcon: $r('app.media.clouddelete'),
              content: '取消云备份'
            })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                await deleteCloudBackup(this.context, item.id)
                this.dialogControllerProgress.close()
                this.loading = true
              })
          }
        }
      }
    }
  }

  @Builder
  NewSheetBuilder() {
    NewTodo({
      teamId: this.teamId
    })
  }

  @Builder
  InfoSheetBuilder(id: string) {
    TodoInfo({
      todoId: id
    })
  }

  @Builder
  UpdateSheetBuilder(id: string) {
    UpdateTodo({
      todoId: id,
      teamId: this.teamId
    })
  }

  build() {
    Scroll() {
      Column() {
        if (this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.cancel'))
            }
            .borderRadius(20)
            .height(40)
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(() => {
              this.multipleSelect = false
              this.multipleSelectArray = []
            })

            Text('已选择 ' + this.multipleSelectArray.length + ' 项')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Column() {
              Image($r('app.media.delete'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (this.multipleSelectArray.length === 0) {
                await promptAction.openToast({
                  message: '未选择'
                })
                return
              }
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
                const promises = this.multipleSelectArray.map(async (item) => {
                  await deleteTodo(this.context, item.id)
                })
                await Promise.all(promises)
                this.multipleSelect = false
                this.multipleSelectArray = []
                this.loading = true
              }
            })

            if (!this.teamId && this.enableCloudBackup) {
              Column() {
                Image($r('app.media.cloud'))
              }
              .borderRadius(20)
              .height(40)
              .margin({
                left: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .padding(11)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
              .onClick(async () => {
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
                for (let i = 0; i < this.multipleSelectArray.length; i++) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '批量云备份中，进度：' + i + '/' + this.multipleSelectArray.length
                    })
                  })
                  dialogControllerProgress.open()
                  await setCloudBackup(this.context, {
                    id: this.multipleSelectArray[i].id,
                    content: JSON.stringify({
                      content: this.multipleSelectArray[i].content,
                      priority: this.multipleSelectArray[i].priority,
                      startTime: this.multipleSelectArray[i].startTime,
                      endTime: this.multipleSelectArray[i].endTime,
                      duration: this.multipleSelectArray[i].duration,
                      recurrenceRule: this.multipleSelectArray[i].recurrenceRule,
                      excludeTime: this.multipleSelectArray[i].excludeTime,
                      tag: this.multipleSelectArray[i].tag,
                      dependency: this.multipleSelectArray[i].dependency,
                      location: this.multipleSelectArray[i].location,
                      action: this.multipleSelectArray[i].action,
                      bz: this.multipleSelectArray[i].bz,
                      recentCompletedTime: this.multipleSelectArray[i].recentCompletedTime,
                      updateTime: this.multipleSelectArray[i].updateTime,
                      cloudBackupTime: this.multipleSelectArray[i].cloudBackupTime
                    })
                  })
                  dialogControllerProgress.close()
                }
                this.multipleSelect = false
                this.multipleSelectArray = []
                this.loading = true
              })
            }
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        if (!this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.new_white'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor(this.buttonHoverId === 0 ? '#0754EB' : $r('sys.color.background_emphasize'))
              },
              pressed: {
                .backgroundColor('#0A50DE')
              }
            })
            .width(40)
            .onHover(isHover => {
              if (!isHover) {
                this.buttonHoverId = -1
              }
              if (isHover) {
                this.buttonHoverId = 0
              }
            })
            .onClick(() => {
              this.isShowNewSheet = true
            })
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

            Blank()
            Text(getDateStringFromTimeStamp(this.currentTime))
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onClick(() => {
                this.UIContext.showDatePickerDialog({
                  selected: this.getDateFromTimeStamp(this.currentTime),
                  onDateAccept: (value) => {
                    this.currentTime =
                      new Date(value.getFullYear(), value.getMonth(), value.getDate(), 0, 0, 0).getTime()
                    this.loading = true
                  }
                })
              })
            if (deviceInfo.deviceType !== '2in1') {
              Column() {
                FunctionComponent({
                  agentId: '',
                  onError: () => {
                  }
                })
              }
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
            }
            Select([
              { value: '个人' }
            ])
              .selected(0)
              .value('个人')
          }
          .width('100%')

          Search({
            placeholder: '请输入内容关键词',
            value: this.contentKeyword!!
          })
            .searchButton('搜索')
            .onSubmit(() => {
              this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                this.tag.every(tagItem => item.tag.includes(tagItem)))
            })
          Scroll() {
            Row() {
              ForEach(this.tags, (item: string, index) => {
                if (!this.tag.includes(item)) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.push(item)
                      this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                        this.tag.every(tagItem => item.tag.includes(tagItem)))
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
                if (this.tag.includes(item)) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.splice(this.tag.indexOf(item), 1)
                      this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                        this.tag.every(tagItem => item.tag.includes(tagItem)))
                    })
                  }
                  .backgroundColor($r('sys.color.background_emphasize'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
              })
            }
          }
          .edgeEffect(EdgeEffect.Spring)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            if (this.todoArray.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.todoArray, (item: Todo, index) => {
              ListItem() {
                Column() {
                  Row() {
                    if (this.multipleSelect) {
                      Toggle({
                        type: ToggleType.Checkbox,
                        isOn: this.multipleSelectArray.some(selectItem => selectItem.id === item.id)
                      })
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onChange(isOn => {
                          if (!isOn) {
                            this.multipleSelectArray.splice(this.multipleSelectArray.findIndex(selectItem => selectItem.id ===
                              item.id), 1)
                          }
                          if (isOn) {
                            this.multipleSelectArray.push(item)
                          }
                        })
                    }
                    if (!this.multipleSelect) {
                      Toggle({
                        type: ToggleType.Checkbox,
                        isOn: item.isCompleted
                      })
                        .enabled(item.canCompleted)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onChange(async (isOn) => {
                          if (!this.teamId) {
                            await completeTodo(this.context, item.id, isOn)
                          }
                          if (this.teamId) {
                            //请求团队完成待办API
                          }
                          this.loading = true
                        })
                    }
                    if (item.isCloudBackup) {
                      Image($r('app.media.cloud'))
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .width('5%')
                    }
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
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            })
            ListItem()
              .margin({
                bottom: this.preferType === 0 ? 80 : 0
              })
          }
        }
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.todoArray = []
          this.tag = []
          this.tags = []
          if (!this.teamId) {
            this.todoArray = await getCurrentTimePersonalTodoList(this.context, this.currentTime)
            const allTagArray: string[] = []
            this.todoArray.forEach(item => {
              item.tag.forEach(tagItem => {
                if (!allTagArray.includes(tagItem)) {
                  allTagArray.push(tagItem)
                }
              })
            })
            this.tags = allTagArray.sort((a, b) => a.localeCompare(b))
            if (deviceInfo.deviceType === '2in1') {
              await syncQuickBarTodo(this.context)
              this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
            }
          }
          if (this.teamId) {
            //请求获取待办列表API
          }
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
      .alignItems(HorizontalAlign.Start)
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshTodo', async () => {
        this.enableCloudBackup = false
        this.loading = true
        const cloudServiceStatus = await getCloudServiceStatus(this.context)
        if (cloudServiceStatus && getKeyAlg()) {
          this.enableCloudBackup = true
        }
      })
      const currentDate = new Date()
      this.currentTime =
        new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 0, 0, 0).getTime()
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus(this.context)
      if (cloudServiceStatus && getKeyAlg()) {
        this.enableCloudBackup = true
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTodo')
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(this.todoId), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '修改待办'
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
}