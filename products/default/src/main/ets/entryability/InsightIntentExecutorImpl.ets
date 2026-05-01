import { common, insightIntent, InsightIntentExecutor } from '@kit.AbilityKit'
import { newTodo, TodoInput } from '../common/Datachange'
import { getRecommendTodoList } from '../common/Dataget'

export default class InsightIntentExecutorImpl extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(name: string,
    param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
    const context = getContext() as common.UIAbilityContext
    const paramString = JSON.stringify(param)
    if (name === 'NewTodo') {
      const paramJson = JSON.parse(paramString) as TodoInput
      await newTodo(context, {
        teamId: '',
        content: paramJson.content,
        priority: paramJson.priority,
        startTime: paramJson.startTime,
        endTime: paramJson.endTime,
        duration: paramJson.duration,
        recurrenceRule: paramJson.recurrenceRule,
        excludeTime: paramJson.excludeTime,
        tag: paramJson.tag,
        dependency: [],
        location: paramJson.location,
        action: paramJson.action,
        bz: paramJson.bz,
        cloudBackup: false
      })
      context.eventHub.emit('refreshTodo')
    }
    if (name === 'GetRecommendTodo') {
      const res = getRecommendTodoList(context)
      return Promise.resolve({
        code: -1,
        result: {
          message: 'success',
          data: res
        }
      } as insightIntent.ExecuteResult)
    }
    return Promise.resolve({
      code: -1,
      result: {
        message: 'fail'
      }
    } as insightIntent.ExecuteResult)
  }
}