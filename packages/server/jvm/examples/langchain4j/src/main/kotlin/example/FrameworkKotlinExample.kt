package example

import app.abto.calling.AbtoConfig
import app.abto.calling.AbtoContext
import app.abto.calling.langchain4j.AbtoLangChain4j
import dev.langchain4j.model.openai.OpenAiChatModel

fun configureKotlinModel(abto: AbtoLangChain4j, builder: OpenAiChatModel.OpenAiChatModelBuilder): OpenAiChatModel {
    abto.forContext(AbtoContext.of("kotlin.graph.reply")).openAiOptions().accept(builder)
    return builder.build()
}
