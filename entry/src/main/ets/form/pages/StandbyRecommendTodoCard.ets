import { FormTodo } from '../../entryformability/EntryFormAbility'

@Entry(new LocalStorage())
@Component
struct StandbyRecommendTodoCard {
  @LocalStorageProp('todoArray') todoArray: FormTodo[] = []

  build() {
    Column() {
      if (this.todoArray.length === 0) {
        Text('无数据')
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
      }
      Column() {
        ForEach(this.todoArray, (item: FormTodo) => {
          Row() {
            Toggle({
              type: ToggleType.Checkbox,
              isOn: item.isCompleted
            })
              .enabled(item.teamId === '')
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onChange(isOn => {
                if (!item.teamId) {
                  postCardAction(this, {
                    action: 'message',
                    params: {
                      action: 'complete',
                      todo: item,
                      isOn: isOn
                    }
                  })
                }
                if (item.teamId) {
                  postCardAction(this, {
                    action: 'router',
                    abilityName: 'EntryAbility'
                  })
                }
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
            .onClick(() => {
              postCardAction(this, {
                action: 'router',
                abilityName: 'EntryAbility',
                params: {
                  action: 'todoInfo',
                  todoId: item.id
                }
              })
            })
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
  }
}