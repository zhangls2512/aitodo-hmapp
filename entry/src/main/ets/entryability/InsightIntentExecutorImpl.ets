import { common, insightIntent, InsightIntentExecutor } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { newTodo, TodoInput } from '../common/Datachange'
import { getRecommendTodoList } from '../common/Dataget'

export default class InsightIntentExecutorImpl extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(name: string, param: Record<string, Object>) {
    const context = getContext() as common.UIAbilityContext
    const paramString = JSON.stringify(param)
    if (name === 'NewTodo') {
      const paramJson = JSON.parse(paramString) as TodoInput
      await newTodo(context, {
        content: paramJson.content ?? '',
        priority: paramJson.priority ?? 0,
        startTime: paramJson.startTime ?? Date.now(),
        endTime: paramJson.endTime ?? -1,
        duration: paramJson.duration ?? 0,
        recurrenceRule: paramJson.recurrenceRule ?? '',
        excludeTime: paramJson.excludeTime ?? [],
        tag: paramJson.tag ?? [],
        dependency: [],
        location: paramJson.location ?? {
          latitude: -1,
          longitude: -1,
          location: ''
        },
        action: paramJson.action ?? [],
        bz: paramJson.bz ?? '',
        cloudBackup: false,
        remind: paramJson.remind ?? false
      })
      context.eventHub.emit('refreshTodo')
    }
    if (name === 'GetRecommendTodo') {
      const res = getRecommendTodoList(context)
      return {
        code: 0,
        result: {
          message: 'success',
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