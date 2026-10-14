package example

import app.abto.calling.AbtoCancellation
import app.abto.calling.AbtoContext
import app.abto.calling.AbtoGateway
import app.abto.calling.AbtoHttpClient
import app.abto.calling.openai.AbtoOpenAI
import com.openai.client.okhttp.OpenAIOkHttpClient
import com.openai.models.chat.completions.ChatCompletionCreateParams
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import kotlinx.coroutines.future.await
import kotlinx.coroutines.runBlocking

fun main(args: Array<String>) = runBlocking {
    ExampleGateway.start(args).use { example ->
        val transport = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NEVER).build()
        try {
            AbtoOpenAI.create(example.config(), transport).use { abto ->
                val params = ChatCompletionCreateParams.builder().model("gpt-4o-mini").addUserMessage("Say hello.").build()
                val cancellation = AbtoCancellation()
                val scope = abto.forContext(AbtoContext("support.kotlin")).withCancellation(cancellation)
                // await() cancels the bound future; the handle also cancels its HTTP call.
                cancellation.bind(scope.openai().async().chat().completions().create(params)).await()

                val existing = OpenAIOkHttpClient.builder().apiKey("transport-placeholder").followRedirects(false).maxRetries(1).build()
                try {
                    val configured = existing.withOptions(abto.forContext(AbtoContext("support.kotlin.config")).openaiOptions(transport))
                    configured.chat().completions().create(params)
                } finally {
                    existing.close()
                }
                val config = example.config()
                val http = AbtoHttpClient.wrap(transport, AbtoGateway(config).forContext(AbtoContext("support.kotlin.http")))
                val request = HttpRequest.newBuilder(config.gatewayBaseUrl().resolve("chat/completions"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString("""{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say hello."}]}"""))
                    .build()
                val response = http.sendAsync(request, HttpResponse.BodyHandlers.ofString()).await()
                check(response.statusCode() == 200) { "HTTP call failed: ${response.statusCode()}" }
                example.verify("support.kotlin", "support.kotlin.config", "support.kotlin.http")
                println("Kotlin factory, coroutine, config and HTTP examples passed.")
            }
        } finally {
            (transport as? AutoCloseable)?.close()
        }
    }
}
