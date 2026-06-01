import { common } from '@kit.AbilityKit'
import { completeTodo } from '../common/Datachange'
import { getRecommendTodoList, Todo } from '../common/Dataget'

@Entry
@ComponentV2
struct Recommendtodostatusbar {
  @Local todoArray: Todo[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    Column() {
      Button('刷新')
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .onClick(async () => {
          this.todoArray = await getRecommendTodoList(this.context)
        })
      if (this.todoArray.length === 0) {
        Text('无数据')
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
      }
      Column() {
        ForEach(this.todoArray, (item: Todo) => {
          Row() {
            Toggle({
              type: ToggleType.Checkbox,
              isOn: item.isCompleted
            })
              .enabled(item.teamId === '')
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
                this.todoArray = await getRecommendTodoList(this.context)
              })
            Column() {
              if (!item.isCompleted) {
                Text(item.content)
                  .fontWeight(FontWeight.Bold)
              }
              if (item.isCompleted) {
                Text(item.content)
                  .decoration({
                    type: TextDecorationType.LineThrough,
                    color: $r('sys.color.font_tertiary')
                  })
                  .fontColor($r('sys.color.font_tertiary'))
                  .fontWeight(FontWeight.Bold)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .borderRadius(12)
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
      }
      .layoutWeight(1)
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .width('100%')
    .onAppear(async () => {
      this.todoArray = await getRecommendTodoList(this.context)
    })
  }
}