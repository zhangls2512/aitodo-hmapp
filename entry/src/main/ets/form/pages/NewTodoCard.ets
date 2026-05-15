@Entry
@Component
struct NewTodoCard {
  build() {
    Column() {
      Image($r('app.media.new_form'))
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          shortcutId: 'newTodo'
        }
      })
    })
  }
}