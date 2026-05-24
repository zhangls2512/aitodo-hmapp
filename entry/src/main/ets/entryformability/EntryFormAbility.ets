import { Want } from '@kit.AbilityKit'
import { fileIo } from '@kit.CoreFileKit'
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit'
import { completeTodo } from '../common/Datachange'
import { getRecommendTodoList } from '../common/Dataget'
import { read, write } from '../common/File'

export interface FormTodo {
  id: string,
  teamId: string,
  content: string,
  isCompleted: boolean
}

interface Message {
  params: MessageParam
}

interface MessageParam {
  action: string,
  todo: FormTodo,
  isOn: boolean
}

export default class EntryFormAbility extends FormExtensionAbility {
  async refresh(formId: string, maxCount: number) {
    const todoArray = await getRecommendTodoList(this.context)
    const updateObject: Record<string, FormTodo[]> = {
      'todoArray': todoArray.slice(0, maxCount).map(item => {
        return {
          id: item.id,
          teamId: item.teamId,
          content: item.content,
          isCompleted: item.isCompleted
        } as FormTodo
      })
    }
    const formData = formBindingData.createFormBindingData(updateObject)
    await formProvider.updateForm(formId, formData)
  }

  onAddForm(want: Want) {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string
    write(this.context.filesDir + '/form/' + formId + '.txt', formName)
    return formBindingData.createFormBindingData()
  }

  async onUpdateForm(formId: string) {
    let maxCount = 20
    const res = await read(this.context.filesDir + '/form/' + formId + '.txt', true)
    if (res === 'standbyrecommendtodo') {
      maxCount = 5
    }
    await this.refresh(formId, maxCount)
  }

  async onRemoveForm(formId: string) {
    const filePath = this.context.filesDir + '/form/' + formId + '.txt'
    if (fileIo.accessSync(filePath)) {
      await fileIo.unlink(filePath)
    }
  }

  async onFormEvent(formId: string, message: string) {
    const messageObject = JSON.parse(message) as Message
    if (messageObject.params.action === 'refresh') {
      await this.refresh(formId, 20)
    }
    if (messageObject.params.action === 'complete') {
      completeTodo(this.context, messageObject.params.todo.id, messageObject.params.isOn)
      setTimeout(async () => {
        await this.refresh(formId, 20)
      }, 100)
    }
  }
}