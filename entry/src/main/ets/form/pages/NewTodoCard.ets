@Entry
@Component
struct NewTodoCard {
  build() {
    Column() {
      Image($r('app.media.new_form'))
    }
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