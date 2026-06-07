import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { TeamCompleteTimeItem, Todo } from '../common/Dataget'
import { teamRequest } from '../common/Request'
import { getDateTimeStringFromTimeStamp } from '../common/Stringformat'

@ComponentV2
export default struct Reviewtodo {
  @Param todoId: string = ''
  @Param todoInfo: string = ''
  @Param teamId: string = ''
  @Local recentCompleteTime: TeamCompleteTimeItem[] | undefined = undefined
  @Local reviewRecentCompleteTime: TeamCompleteTimeItem[] | undefined = undefined
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  userNameMap = new Map<string, string>()
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  async review(uid: string, finished: boolean) {
    this.dialogControllerProgress.open()
    const res = await teamRequest(this.context, this.teamId, '/reviewTodoComplete', {
      todoId: this.todoId,
      userId: uid,
      finished: finished
    })
    this.dialogControllerProgress.close()
    if (res !== 'fail') {
      await promptAction.openToast({
        message: (finished ? '通过' : '驳回') + '成功'
      })
      if (this.recentCompleteTime && this.reviewRecentCompleteTime) {
        const indexa = this.recentCompleteTime.findIndex(item => item.uid === uid)
        const indexb = this.reviewRecentCompleteTime.findIndex(item => item.uid === uid)
        if (!finished) {
          if (indexa !== -1) {
            this.recentCompleteTime.splice(indexa, 1)
          }
          if (indexb !== -1) {
            this.reviewRecentCompleteTime.splice(indexb, 1)
          }
        }
        if (finished) {
          this.recentCompleteTime.push(this.reviewRecentCompleteTime[indexb])
          this.reviewRecentCompleteTime.splice(indexb, 1)
        }
      }
    }
  }

  build() {
    List() {
      if (this.recentCompleteTime) {
        ListItem() {
          Text('已审核')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.recentCompleteTime.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.recentCompleteTime, (item: TeamCompleteTimeItem) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text('名：' + this.userNameMap.get(item.uid))
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                  Text('完成时间：' + getDateTimeStringFromTimeStamp(item.time))
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Image($r('app.media.close'))
                  .height(24)
                  .onClick(async () => {
                    await this.review(item.uid, false)
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
      }
      if (this.reviewRecentCompleteTime) {
        ListItem() {
          Text('待审核')
            .fontWeight(FontWeight.Medium)
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        if (this.reviewRecentCompleteTime.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.reviewRecentCompleteTime, (item: TeamCompleteTimeItem) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text('名：' + this.userNameMap.get(item.uid))
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                  Text('完成时间：' + getDateTimeStringFromTimeStamp(item.time))
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Image($r('app.media.success'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    await this.review(item.uid, true)
                  })
                Image($r('app.media.close'))
                  .height(24)
                  .onClick(async () => {
                    await this.review(item.uid, false)
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
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      const todoInfo = JSON.parse(this.todoInfo) as Todo
      if (todoInfo) {
        const recentCompleteTime = todoInfo.recentCompleteTime
        const reviewRecentCompleteTime = todoInfo.reviewRecentCompleteTime
        this.dialogControllerProgress.open()
        if (recentCompleteTime) {
          for (let i = 0; i < recentCompleteTime.length; i++) {
            const item = recentCompleteTime[i]
            if (!this.userNameMap.has(item.uid)) {
              const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                id: item.uid
              })
              if (res !== 'fail') {
                this.userNameMap.set(item.uid, JSON.parse(res).name)
              }
              if (res === 'fail') {
                this.userNameMap.set(item.uid, '未知')
              }
            }
          }
        }
        this.recentCompleteTime = todoInfo.recentCompleteTime
        if (reviewRecentCompleteTime) {
          for (let i = 0; i < reviewRecentCompleteTime.length; i++) {
            const item = reviewRecentCompleteTime[i]
            if (!this.userNameMap.has(item.uid)) {
              const res = await teamRequest(this.context, this.teamId, '/getUserName', {
                id: item.uid
              })
              if (res !== 'fail') {
                this.userNameMap.set(item.uid, JSON.parse(res).name)
              }
              if (res === 'fail') {
                this.userNameMap.set(item.uid, '未知')
              }
            }
          }
        }
        this.reviewRecentCompleteTime = todoInfo.reviewRecentCompleteTime
        this.dialogControllerProgress.close()
      }
    })
  }
}