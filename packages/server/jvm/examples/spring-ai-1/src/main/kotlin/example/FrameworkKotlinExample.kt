package example

import app.abto.calling.AbtoConfig
import app.abto.calling.AbtoContext
import app.abto.calling.springai1.AbtoSpringAI1
import org.springframework.ai.openai.OpenAiChatModel
import org.springframework.ai.openai.api.OpenAiApi
import org.springframework.web.client.RestClient

fun configureKotlinModel(abto: AbtoSpringAI1, builder: OpenAiChatModel.Builder,
                         rest: RestClient.Builder): OpenAiChatModel {
    val scope = abto.forContext(AbtoContext.of("kotlin.spring.reply"))
    val api = OpenAiApi.builder()
    scope.openAiApiOptions(rest).accept(api)
    scope.chatModelOptions(api.build()).accept(builder)
    return builder.build()
}
