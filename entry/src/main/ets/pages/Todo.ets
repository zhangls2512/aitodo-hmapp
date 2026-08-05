import { common } from '@kit.AbilityKit'
import { FunctionComponent } from '@kit.AgentFrameworkKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { LoadingDialog, promptAction, uiMaterial } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { getTeamAccountInfo, getTeamAccountList } from '../common/Account'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { completeTodo, deleteCloudBackup, deleteTodo, setCloudBackup } from '../common/Datachange'
import { getCurrentTimePersonalTodoList, Todo } from '../common/Dataget'
import { TodoItem } from '../common/Dataimport'
import { write } from '../common/File'
import { icsstringify } from '../common/Ics'
import { getPreferType } from '../common/Prefertype'
import { deleteQuickBarTodo, getQuickBarTodoIdList, setQuickBarTodo, syncQuickBarTodo } from '../common/Quickbar'
import { teamRequest } from '../common/Request'
import { getDateStringFromTimeStamp, getDateTimeStringFromTimeStamp, getSizeString } from '../common/Stringformat'
import { autoBackupTable, autoSyncTable } from '../common/Table'
import { syncCompleteTeamTodo } from '../common/Teamutil'
import NewTodo from './Newtodo'
import ReviewTodo from './Reviewtodo'
import TodoInfo from './Todoinfo'
import UpdateTodo from './Updatetodo'

interface TypeItem {
  name: string,
  value: string
}

@ComponentV2
export default struct TodoPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local isShowInfoSheet: boolean = false
  @Local isShowReviewSheet: boolean = false
  @Local preferType: number = 1
  @Local todoArray: Todo[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local teamId: string = ''
  @Local teamNameArray: string[] = []
  @Local teamIndex: number = 0
  @Local teamValue: string = '个人'
  @Local currentTime: number = -1
  @Local timeStamp: number = Date.now()
  @Local contentKeyword: string = ''
  @Local tag: string[] = []
  @Local tags: string[] = []
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Todo[] = []
  @Local quickBarTodoIdArray: string[] = []
  @Local type: string = 'complete'
  @Local teamAdmin: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  todoId = ''
  todoInfo = ''
  lastCount = -1
  teamIdArray: string[] = []
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  typeArray: TypeItem[] = [
    {
      name: '执行',
      value: 'complete'
    },
    {
      name: '查看',
      value: 'get'
    },
    {
      name: '审核',
      value: 'review'
    },
    {
      name: '创建',
      value: 'create'
    }
  ]

  getDateFromTimeStamp(timeStamp: number) {
    const date = new Date(timeStamp)
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0)
  }

  generateTagArray() {
    const allTagArray: string[] = []
    this.todoArray.forEach(item => {
      item.tag.forEach(tagItem => {
        if (!allTagArray.includes(tagItem)) {
          allTagArray.push(tagItem)
        }
      })
    })
    this.tags = allTagArray.sort((a, b) => a.localeCompare(b))
    this.tag = this.tag.filter(item => this.tags.includes(item))
  }

  async shareTodo(todoArray: Todo[]) {
    const todos: TodoItem[] = []
    todoArray.forEach(item => {
      todos.push({
        id: item.id,
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
        recentCompletedTime: -1,
        updateTime: item.updateTime,
        cloudBackupTime: []
      })
    })
    const promptAction = this.UIContext.getPromptAction()
    const data = await promptAction.showActionMenu({
      title: '选择分享方式',
      buttons: [
        {
          text: '系统分享',
          color: $r('sys.color.font_primary')
        },
        {
          text: '碰一碰 / 隔空传送 (txt)',
          color: $r('sys.color.font_primary')
        },
        {
          text: '碰一碰 / 隔空传送 (ics)',
          color: $r('sys.color.font_primary')
        },
        {
          text: '链接',
          color: $r('sys.color.font_primary')
        },
        {
          text: '二维码',
          color: $r('sys.color.font_primary')
        }
      ]
    })
    if (data.index === 0) {
      const vcsPath = this.context.tempDir + '/todo.vcs'
      const icsPath = this.context.tempDir + '/todo.ics'
      const txtPath = this.context.tempDir + '/todo.txt'
      const ics = icsstringify(todos)
      await write(vcsPath, ics)
      await write(icsPath, ics)
      await write(txtPath, JSON.stringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.VCS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        label: '日历日程 (.vcs)',
        description: getSizeString(fileIo.statSync(vcsPath).size),
        uri: fileUri.getUriFromPath(vcsPath)
      })
      shareData.addRecord({
        utd: uniformTypeDescriptor.UniformDataType.ICS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        label: '日历日程 (.ics)',
        description: getSizeString(fileIo.statSync(icsPath).size),
        uri: fileUri.getUriFromPath(icsPath)
      })
      shareData.addRecord({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(txtPath).size),
        uri: fileUri.getUriFromPath(txtPath)
      })
      const shareController = new systemShare.ShareController(shareData)
      await shareController.show(this.context, {})
    }
    if (data.index === 1) {
      const filePath = this.context.tempDir + '/todo.txt'
      await write(filePath, JSON.stringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(filePath).size),
        uri: fileUri.getUriFromPath(filePath)
      })
      harmonyShare.on('knockShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      harmonyShare.on('gesturesShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      await promptAction.showDialog({
        title: '提示',
        message: '碰一碰/隔空传送邻近设备即可分享，关闭此弹窗后停止分享',
        buttons: [
          {
            text: '关闭',
            color: $r('sys.color.warning')
          }
        ],
        onDidDisappear: async () => {
          await fileIo.unlink(filePath)
          harmonyShare.off('knockShare')
          harmonyShare.off('gesturesShare')
        }
      })
    }
    if (data.index === 2) {
      const filePath = this.context.tempDir + '/todo.ics'
      await write(filePath, icsstringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.ICS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(filePath).size),
        uri: fileUri.getUriFromPath(filePath)
      })
      harmonyShare.on('knockShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      harmonyShare.on('gesturesShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      await promptAction.showDialog({
        title: '提示',
        message: '碰一碰/隔空传送邻近设备即可分享，关闭此弹窗后停止分享',
        buttons: [
          {
            text: '关闭',
            color: $r('sys.color.warning')
          }
        ],
        onDidDisappear: async () => {
          await fileIo.unlink(filePath)
          harmonyShare.off('knockShare')
          harmonyShare.off('gesturesShare')
        }
      })
    }
    if (data.index === 3 || data.index === 4) {
      const urires = new uri.URI('https://www.zhangls2512.cn/product/todo')
      const url = urires.addQueryValue('share', JSON.stringify(todos)).toString()
      if (data.index === 3) {
        const shareData = new systemShare.SharedData({
          utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
          title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
          content: url
        })
        const shareController = new systemShare.ShareController(shareData)
        await shareController.show(this.context, {})
      }
      if (data.index === 4) {
        const qrcodePath = this.context.tempDir + '/todoqrcode.png'
        let qrcodeUri = ''
        try {
          const qrcodePixelMap = await generateBarcode.createBarcode(url, {
            scanType: scanCore.ScanType.QR_CODE,
            width: 200,
            height: 200
          })
          const qrcodeFile = fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
          const imagePacker = image.createImagePacker()
          await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
            format: 'image/png',
            quality: 100
          })
          await imagePacker.release()
          await qrcodePixelMap.release()
          fileIo.closeSync(qrcodeFile)
          const qrcodeFileUri = fileUri.getUriFromPath(qrcodePath)
          qrcodeUri = qrcodeFileUri
        } catch {
          const qrcodeFile = fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
          const qrcodeFileStream = fileIo.fdopenStreamSync(qrcodeFile.fd, 'w+')
          netBoost.setSceneDesc({
            scene: 'download',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
          })
          const session = rcp.createSession({
            requestConfiguration: {
              tracing: {
                httpEventsHandler: {
                  onDataReceive: async (incomingData) => {
                    await qrcodeFileStream.write(incomingData)
                  },
                  onDataEnd: () => {
                    this.dialogControllerProgress.close()
                    session.close()
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                    })
                    qrcodeFileStream.closeSync()
                  }
                }
              },
              security: {
                tlsRange: {
                  min: 'TlsV1.2'
                }
              }
            }
          })
          this.dialogControllerProgress.open()
          try {
            const response = await session.get('https://uapis.cn/api/v1/image/qrcode?text=' + encodeURIComponent(url))
            session.close()
            this.dialogControllerProgress.close()
            if (response.statusCode >= 200 && response.statusCode < 300) {
              qrcodeUri = fileUri.getUriFromPath(qrcodePath)
            } else {
              await promptAction.openToast({
                message: 'HTTP 请求失败，状态码：' + response.statusCode
              })
            }
          } catch (err) {
            this.dialogControllerProgress.close()
            session.close()
            netBoost.setSceneDesc({
              scene: 'download',
              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
            })
            qrcodeFileStream.closeSync()
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
            })
          }
        }
        if (qrcodeUri) {
          const shareData = new systemShare.SharedData({
            utd: uniformTypeDescriptor.UniformDataType.IMAGE,
            title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
            thumbnailUri: qrcodeUri,
            uri: qrcodeUri
          })
          const shareController = new systemShare.ShareController(shareData)
          await shareController.show(this.context, {})
        }
      }
    }
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
        if (!this.teamId) {
          MenuItem({
            startIcon: $r('app.media.multipleselect'),
            content: '多选'
          })
            .onClick(() => {
              this.multipleSelect = true
              this.multipleSelectArray.push(item)
            })
        }
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
            this.todoInfo = JSON.stringify(item)
            this.isShowInfoSheet = true
          })
        if (!this.teamId) {
          MenuItem({
            startIcon: $r('app.media.share'),
            content: '分享'
          })
            .onClick(async () => {
              await this.shareTodo([item])
            })
        }
        if (this.teamId && this.type === 'review') {
          MenuItem({
            startIcon: $r('app.media.review'),
            content: '审核'
          })
            .onClick(() => {
              this.todoId = item.id
              this.todoInfo = JSON.stringify(item)
              this.isShowReviewSheet = true
            })
        }
        if (!this.teamId || this.type === 'create' || (this.type === 'get' && this.teamAdmin)) {
          MenuItem({
            startIcon: $r('app.media.edit'),
            content: '修改'
          })
            .onClick(() => {
              this.todoId = item.id
              this.todoInfo = JSON.stringify(item)
              this.isShowUpdateSheet = true
            })
          MenuItem({
            startIcon: $r('app.media.delete'),
            content: '删除'
          })
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (!this.teamId) {
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
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id)
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
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
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id, true, item.excludeTime.concat([item.startTime]))
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                  if (data.index === 1) {
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id)
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
                this.loading = true
              }
              if (this.teamId) {
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
                    this.dialogControllerProgress.open()
                    const res = await teamRequest(this.context, this.teamId, '/deleteTodo', {
                      id: item.id
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      this.loading = true
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      this.loading = true
                    }
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
                    this.dialogControllerProgress.open()
                    const res = await teamRequest(this.context, this.teamId, '/deleteTodo', {
                      id: item.id
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      this.loading = true
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      this.loading = true
                    }
                  }
                  if (data.index === 1) {
                    this.dialogControllerProgress.open()
                    const res = await teamRequest(this.context, this.teamId, '/updateTodo', {
                      id: item.id,
                      content: item.content,
                      priority: item.priority,
                      startTime: item.startTime,
                      endTime: item.endTime,
                      duration: item.duration,
                      recurrenceRule: item.recurrenceRule,
                      excludeTime: item.excludeTime.concat([item.startTime]),
                      tag: item.tag,
                      dependency: item.dependency,
                      location: item.location,
                      action: item.action,
                      bz: item.bz
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      this.loading = true
                      await promptAction.openToast({
                        message: '删除成功'
                      })
                      this.loading = true
                    }
                  }
                }
              }
            })
        }
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
                await promptAction.openToast({
                  message: '云备份成功'
                })
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
                await promptAction.openToast({
                  message: '取消云备份成功'
                })
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
  InfoSheetBuilder() {
    TodoInfo({
      todoId: this.todoId,
      teamId: this.teamId,
      todoInfo: this.todoInfo
    })
  }

  @Builder
  ReviewSheetBuilder() {
    ReviewTodo({
      todoId: this.todoId,
      teamId: this.teamId,
      todoInfo: this.todoInfo
    })
  }

  @Builder
  UpdateSheetBuilder() {
    UpdateTodo({
      todoId: this.todoId,
      teamId: this.teamId,
      todoInfo: this.todoInfo
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
            .keyboardShortcut(FunctionKey.ESC, [])
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
            .systemMaterial(new uiMaterial.ImmersiveMaterial({
              style: uiMaterial.ImmersiveStyle.REGULAR,
              interactive: true,
              lightEffect: {
                color: Color.White
              }
            }))
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
              Image($r('app.media.share'))
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
            .systemMaterial(new uiMaterial.ImmersiveMaterial({
              style: uiMaterial.ImmersiveStyle.REGULAR,
              interactive: true,
              lightEffect: {
                color: Color.White
              }
            }))
            .width(40)
            .onClick(async () => {
              await this.shareTodo(this.multipleSelectArray)
              this.multipleSelect = false
              this.multipleSelectArray = []
            })

            Column() {
              Image($r('app.media.delete'))
            }
            .borderRadius(20)
            .height(40)
            .keyboardShortcut('D', [ModifierKey.CTRL])
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
            .systemMaterial(new uiMaterial.ImmersiveMaterial({
              style: uiMaterial.ImmersiveStyle.REGULAR,
              interactive: true,
              lightEffect: {
                color: Color.White
              }
            }))
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
                for (let i = 0; i < this.multipleSelectArray.length; i++) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '批量删除中，进度：' + (i + 1) + '/' + this.multipleSelectArray.length
                    })
                  })
                  dialogControllerProgress.open()
                  await deleteTodo(this.context, this.multipleSelectArray[i].id, false)
                  dialogControllerProgress.close()
                  await promptAction.openToast({
                    message: '删除成功'
                  })
                }
                this.loading = true
                await autoSyncTable(this.context)
                await autoBackupTable(this.context)
              }
            })

            if (this.enableCloudBackup) {
              Column() {
                Image($r('app.media.cloud'))
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
              .systemMaterial(new uiMaterial.ImmersiveMaterial({
                style: uiMaterial.ImmersiveStyle.REGULAR,
                interactive: true,
                lightEffect: {
                  color: Color.White
                }
              }))
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
                      content: '批量云备份中，进度：' + (i + 1) + '/' + this.multipleSelectArray.length
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
                  }, false)
                  dialogControllerProgress.close()
                  await promptAction.openToast({
                    message: '云备份成功'
                  })
                }
                this.loading = true
                await autoSyncTable(this.context)
                await autoBackupTable(this.context)
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
            .keyboardShortcut('N', [ModifierKey.CTRL, ModifierKey.SHIFT])
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.background_emphasize'))
              },
              hovered: {
                .backgroundColor('#0754EB')
              },
              pressed: {
                .backgroundColor('#0A50DE')
              }
            })
            .width(40)
            .onClick(() => {
              this.isShowNewSheet = true
            })
            .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '新增待办'
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
              .layoutWeight(1)
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
                  agentId: 'agent5e4f855080cf442ebf578126e9117b4a',
                  onError: () => {
                  }
                })
              }
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .systemMaterial(new uiMaterial.ImmersiveMaterial({
                style: uiMaterial.ImmersiveStyle.REGULAR,
                interactive: true,
                lightEffect: {
                  color: Color.White
                }
              }))
              .width(40)
            }
            Select(this.teamNameArray.map((item): SelectOption => {
              return {
                value: item
              }
            }))
              .selected(this.teamIndex!!)
              .value(this.teamValue!!)
              .onSelect(async (index) => {
                this.teamAdmin = false
                if (index === 0) {
                  this.type = ''
                  this.teamId = ''
                } else {
                  if (!this.teamId) {
                    this.type = 'complete'
                  }
                  this.teamId = this.teamIdArray[this.teamIndex - 1]
                  const teamAccountInfo = await getTeamAccountInfo(this.teamId)
                  this.teamAdmin = teamAccountInfo.admin === 'true' ? true : false
                }
                this.loading = true
              })
          }

          if (this.teamId) {
            Row() {
              ForEach(this.typeArray, (item: TypeItem, index) => {
                Text(item.name)
                  .fontColor(this.type === item.value ? $r('sys.color.font_emphasize') : '')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    left: index !== 0 ? $r('sys.float.ohos_id_elements_margin_horizontal_m') : 0
                  })
                  .onClick(() => {
                    if (this.type !== item.value) {
                      this.type = item.value
                      this.loading = true
                    }
                  })
              })
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
          Search({
            placeholder: '请输入内容关键词',
            value: this.contentKeyword!!
          })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .searchButton('搜索')
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
            bottom: this.tags.length === 0 ? 0 : $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        if (this.todoArray.length === 0 && !this.loading) {
          Text('无数据')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            ForEach(this.todoArray, (item: Todo) => {
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
                            this.multipleSelectArray.splice(
                              this.multipleSelectArray.findIndex(selectItem => selectItem.id ===
                                item.id), 1)
                          }
                          if (isOn) {
                            this.multipleSelectArray.push(item)
                          }
                        })
                    }
                    if (!this.multipleSelect && (!this.teamId || this.type === 'complete')) {
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
                            this.dialogControllerProgress.open()
                            await completeTodo(this.context, item.id, isOn)
                            this.dialogControllerProgress.close()
                            this.loading = true
                          }
                          if (this.teamId) {
                            this.dialogControllerProgress.open()
                            const res = await teamRequest(this.context, this.teamId, '/completeTodo', {
                              id: item.id
                            })
                            this.dialogControllerProgress.close()
                            if (res !== 'fail') {
                              if (!isOn) {
                                await promptAction.openToast({
                                  message: '已取消完成'
                                })
                              }
                              if (isOn) {
                                await promptAction.openToast({
                                  message: '已完成'
                                })
                              }
                              this.dialogControllerProgress.open()
                              await syncCompleteTeamTodo(this.context, this.teamId)
                              this.dialogControllerProgress.close()
                              this.loading = true
                            }
                          }
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
                      if (!item.isCompleted || (this.teamId && this.type !== 'complete')) {
                        Text(item.content)
                          .enableAutoSpacing(true)
                          .fontColor(
                            (item.endTime !== -1 && item.endTime < this.timeStamp) ? $r('sys.color.warning') : '')
                          .fontWeight(FontWeight.Bold)
                      }
                      if (item.isCompleted && (!this.teamId || (this.teamId && this.type === 'complete'))) {
                        Text(item.content)
                          .decoration({
                            type: TextDecorationType.LineThrough,
                            color: $r('sys.color.font_tertiary')
                          })
                          .enableAutoSpacing(true)
                          .fontColor($r('sys.color.font_tertiary'))
                          .fontWeight(FontWeight.Bold)
                      }
                      if (this.teamId) {
                        if (this.type === 'complete' && item.status) {
                          if (item.status === 'pending') {
                            Text('待完成')
                              .fontColor($r('sys.color.warning'))
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                          }
                          if (item.status === 'reviewing') {
                            Text('待审核')
                              .fontColor(Color.Orange)
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                          }
                          if (item.status === 'finished') {
                            Text('已完成')
                              .fontColor(Color.Green)
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                          }
                        }
                        if (this.type === 'review' && item.reviewRecentCompleteTime) {
                          Text('待审核' + item.reviewRecentCompleteTime.length)
                            .enableAutoSpacing(true)
                            .fontColor(Color.Orange)
                            .fontWeight(FontWeight.Medium)
                            .margin({
                              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                            })
                        }
                        if (this.type === 'get' && item.allowCompleteUids && item.reviewRecentCompleteTime &&
                          item.recentCompleteTime) {
                          Row() {
                            Text('待完成' + (item.allowCompleteUids.length - item.recentCompleteTime.length -
                              item.reviewRecentCompleteTime.length))
                              .enableAutoSpacing(true)
                              .fontColor($r('sys.color.warning'))
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                right: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                            Text('待审核' + item.reviewRecentCompleteTime.length)
                              .enableAutoSpacing(true)
                              .fontColor(Color.Orange)
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                right: $r('sys.float.ohos_id_elements_margin_horizontal_m'),
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                            Text('已完成' + item.recentCompleteTime.length)
                              .enableAutoSpacing(true)
                              .fontColor(Color.Green)
                              .fontWeight(FontWeight.Medium)
                              .margin({
                                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                              })
                          }
                        }
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
                            .enableDataDetector(true)
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
                      .backgroundColor($r('sys.color.comp_background_primary'))
                    },
                    hovered: {
                      .backgroundColor($r('sys.color.interactive_hover'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
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
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .selected(this.multipleSelectArray.some(selectItem => selectItem.id === item.id))
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .visibility(
                (item.content.includes(this.contentKeyword) && this.tag.every(tagItem => item.tag.includes(tagItem))) ?
                  Visibility.Visible : Visibility.None)
              .onSelect(isSelected => {
                if (!isSelected) {
                  this.multipleSelectArray = this.multipleSelectArray.filter(selectItem => selectItem.id !== item.id)
                }
                if (isSelected) {
                  this.multipleSelect = true
                  if (!this.multipleSelectArray.find(selectItem => selectItem.id === item.id)) {
                    this.multipleSelectArray.push(item)
                  }
                }
              })
            })
            ListItem()
              .margin({
                bottom: 80
              })
          }
          .height('100%')
          .lanes({
            fillType: PresetFillType.BREAKPOINT_DEFAULT
          }, $r('sys.float.ohos_id_elements_margin_horizontal_m'))
          .multiSelectable(true)
          .onReachEnd(async () => {
            if (this.teamId && this.todoArray.length > 0 && this.lastCount === 10 && !this.contentKeyword &&
              this.tag.length === 0) {
              this.dialogControllerProgress.open()
              const res = await teamRequest(this.context, this.teamId, '/getTodoList', {
                type: this.type,
                time: this.currentTime,
                skip: this.todoArray.length
              })
              this.dialogControllerProgress.close()
              if (res !== 'fail') {
                const todoArray = JSON.parse(res).data as Todo[]
                todoArray.forEach(item => {
                  item.canCompleted = item.startTime <= this.timeStamp &&
                    ((item.endTime >= this.timeStamp && item.endTime !== -1) || item.endTime === -1)
                  item.isCompleted = item.status === 'pending' ? false : true
                })
                this.todoArray = this.todoArray.concat(todoArray)
                this.generateTagArray()
              }
            }
          })
        }
        .keyboardShortcut('R', [ModifierKey.CTRL], () => {
          this.loading = true
        })
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.tags = []
          this.multipleSelect = false
          this.multipleSelectArray = []
          this.todoArray = []
          this.timeStamp = Date.now()
          if (!this.teamId) {
            this.todoArray = await getCurrentTimePersonalTodoList(this.context, this.currentTime)
            if (deviceInfo.deviceType === '2in1') {
              await syncQuickBarTodo(this.context)
              this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
            }
          }
          if (this.teamId) {
            this.dialogControllerProgress.open()
            const res = await teamRequest(this.context, this.teamId, '/getTodoList', {
              type: this.type,
              time: this.currentTime
            })
            this.dialogControllerProgress.close()
            if (res !== 'fail') {
              const todoArray = JSON.parse(res).data as Todo[]
              todoArray.forEach(item => {
                item.canCompleted = item.startTime <= this.timeStamp &&
                  ((item.endTime >= this.timeStamp && item.endTime !== -1) || item.endTime === -1)
                item.isCompleted = item.status === 'pending' ? false : true
              })
              this.todoArray = todoArray
              this.lastCount = this.todoArray.length
            }
          }
          this.generateTagArray()
          this.loading = false
        })
        .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '待办详情'
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
      .bindSheet(this.isShowReviewSheet!!, this.ReviewSheetBuilder(), {
        preferType: this.preferType,
        title: {
          title: '审核待办'
        }
      })
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshTodo', async (refresh: string) => {
        if (refresh !== 'false') {
          const teamAccountArray = await getTeamAccountList()
          this.teamIdArray = teamAccountArray.map(item => item.teamId)
          this.teamNameArray = ['个人'].concat(teamAccountArray.map(item => item.teamName))
          const index = this.teamNameArray.indexOf(this.teamValue)
          if (index === -1) {
            this.teamId = ''
            this.teamIndex = 0
            this.teamValue = '个人'
          }
          this.loading = true
          if (!this.teamId) {
            this.enableCloudBackup = false
            const cloudServiceStatus = await getCloudServiceStatus(this.context)
            if (cloudServiceStatus && getKeyAlg()) {
              this.enableCloudBackup = true
            }
          }
          if (this.teamId) {
            const teamAccountInfo = await getTeamAccountInfo(this.teamId)
            this.teamAdmin = teamAccountInfo.admin === 'true' ? true : false
          }
        }
      })
      const currentDate = new Date()
      this.currentTime =
        new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 0, 0, 0).getTime()
      const teamAccountArray = await getTeamAccountList()
      this.teamIdArray = teamAccountArray.map(item => item.teamId)
      this.teamNameArray = ['个人'].concat(teamAccountArray.map(item => item.teamName))
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus(this.context)
      if (cloudServiceStatus && getKeyAlg()) {
        this.enableCloudBackup = true
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTodo')
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '修改待办'
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