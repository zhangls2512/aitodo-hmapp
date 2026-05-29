import { common, insightIntent, InsightIntentExecutor } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { newTodo, TodoInput } from '../common/Datachange'
import { getCurrentTimePersonalTodoList, getRecommendTodoList } from '../common/Dataget'

interface GetInput {
  currentTime: number
}

export default class InsightIntentExecutorImpl extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(name: string, param: Record<string, Object>) {
    const context = getContext() as common.UIAbilityContext
    const paramString = JSON.stringify(param)
    if (name === 'NewTodo') {
      const paramJson = JSON.parse(paramString) as TodoInput
      await newTodo(context, {
        content: paramJson.content ?? '',
        priority: paramJson.priority ?? 0,
        startTime: paramJson.startTime >= 0 ? paramJson.startTime * 1000 : Date.now(),
        endTime: paramJson.endTime >= 0 ? paramJson.endTime * 1000 : -1,
        duration: paramJson.duration ?? 0,
        recurrenceRule: paramJson.recurrenceRule ?? '',
        excludeTime: [],
        tag: paramJson.tag ?? [],
        dependency: [],
        location: paramJson.location ?? {
          latitude: -1,
          longitude: -1,
          location: ''
        },
        action: [],
        bz: paramJson.bz ?? '',
        cloudBackup: false,
        remind: paramJson.remind ?? false
      })
      context.eventHub.emit('refreshTodo')
    }
    if (name === 'GetRecommendTodo') {
      const res = await getRecommendTodoList(context)
      return {
        code: 0,
        result: {
          data: res
        }
      } as insightIntent.ExecuteResult
    }
    if (name === 'GetCurrentTimePersonalTodo') {
      const paramJson = JSON.parse(paramString) as GetInput
      const date = new Date()
      const res = await getCurrentTimePersonalTodoList(context,
        paramJson.currentTime >= 0 ? paramJson.currentTime * 1000 :
          new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0).getTime())
      return {
        code: 0,
        result: {
          data: res
        }
      } as insightIntent.ExecuteResult
    }
    await promptAction.openToast({
      message: '新增成功'
    })
    return {
      code: 0,
      result: {
        message: 'success'
      }
    } as insightIntent.ExecuteResult
  }
}