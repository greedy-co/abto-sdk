package example

import app.abto.calling.AbtoConfig
import app.abto.calling.AbtoContext
import app.abto.calling.springai2.AbtoSpringAI2
import org.springframework.ai.openai.OpenAiChatModel

fun configureKotlinModel(abto: AbtoSpringAI2, builder: OpenAiChatModel.Builder): OpenAiChatModel {
    abto.forContext(AbtoContext.of("kotlin.spring.reply")).chatModelOptions().accept(builder)
    return builder.build()
}
