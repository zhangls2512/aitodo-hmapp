import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit'
import { completeTodo } from '../common/Datachange'
import { getRecommendTodoList } from '../common/Dataget'

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
  async refresh(formId: string) {
    const todoArray = await getRecommendTodoList(this.context)
    const updateObject: Record<string, FormTodo[]> = {
      'todoArray': todoArray.slice(0, 10).map(item => {
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

  async onUpdateForm(formId: string) {
    await this.refresh(formId)
  }

  async onFormEvent(formId: string, message: string) {
    const messageObject = JSON.parse(message) as Message
    if (messageObject.params.action === 'refresh') {
      await this.refresh(formId)
    }
    if (messageObject.params.action === 'complete') {
      if (!messageObject.params.todo.teamId) {
        completeTodo(this.context, messageObject.params.todo.id, messageObject.params.isOn)
      }
      if (messageObject.params.todo.teamId) {
        //请求团队完成待办API
      }
      setTimeout(async () => {
        await this.refresh(formId)
      }, 100)
    }
  }
}