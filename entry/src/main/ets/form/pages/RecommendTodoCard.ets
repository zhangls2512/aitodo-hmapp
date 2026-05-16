import { FormTodo } from '../../entryformability/EntryFormAbility'

@Entry
@Component
struct RecommendTodoCard {
  @LocalStorageProp('todoArray') todoArray: FormTodo[] = []

  build() {
    Column() {
      Button('刷新')
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: {
              action: 'refresh'
            }
          })
        })
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
          .height('10%')
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .padding(12)
        })
      }
      .layoutWeight(1)
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .width('100%')
  }
}