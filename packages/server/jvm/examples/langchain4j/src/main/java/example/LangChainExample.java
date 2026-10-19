package example;

import app.abto.calling.AbtoContext;
import app.abto.calling.langchain4j.AbtoLangChain4j;
import dev.langchain4j.model.openai.OpenAiChatModel;
import org.bsc.langgraph4j.GraphInput;
import org.bsc.langgraph4j.RunnableConfig;
import org.bsc.langgraph4j.StateGraph;
import org.bsc.langgraph4j.state.AgentState;
import java.util.Map;
import static org.bsc.langgraph4j.action.AsyncNodeAction.node_async;

public final class LangChainExample {
    public static void main(String[] args) throws Exception {
        try (var example = ExampleGateway.start(args); var abto = AbtoLangChain4j.create(example.config())) {
            var builder = OpenAiChatModel.builder().modelName("gpt-4o-mini");
            abto.forContext(AbtoContext.of("support.langchain")).openAiOptions().accept(builder);
            builder.build().chat("Say hello.");

            var graph = new StateGraph<AgentState>(AgentState::new)
                    .addNode("reply", node_async(state -> {
                        var model = OpenAiChatModel.builder().modelName("gpt-4o-mini");
                        abto.forContext(AbtoContext.of(state.<String>value("featureId").orElseThrow())).openAiOptions().accept(model);
                        return Map.of("answer", model.build().chat(state.<String>value("input").orElseThrow()));
                    })).addEdge(StateGraph.START, "reply").addEdge("reply", StateGraph.END).compile();
            graph.invoke(GraphInput.args(Map.of("featureId", "support.graph", "input", "Say hello.")), RunnableConfig.empty()).orElseThrow();
            example.verify("support.langchain", "support.graph");
            System.out.println("LangChain4j and LangGraph4j examples passed.");
        }
    }
}
