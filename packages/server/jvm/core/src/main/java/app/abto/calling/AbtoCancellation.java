package app.abto.calling;

import java.util.Set;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

/** Explicit cancellation across SDKs whose dependent futures do not cancel their HTTP calls. */
public final class AbtoCancellation {
    private final AtomicBoolean cancelled = new AtomicBoolean();
    private final Set<CompletableFuture<?>> pending = ConcurrentHashMap.newKeySet();

    public boolean isCancelled() { return cancelled.get(); }
    public void cancel() {
        if (cancelled.compareAndSet(false, true)) pending.forEach(future -> future.cancel(true));
    }
    /** Bind the official SDK future before returning it to a caller or awaiting it in a coroutine. */
    public <T> CompletableFuture<T> bind(CompletableFuture<T> future) {
        track(future);
        future.whenComplete((value, error) -> { if (future.isCancelled()) cancel(); });
        return future;
    }
    void track(CompletableFuture<?> future) {
        pending.add(future);
        future.whenComplete((value, error) -> pending.remove(future));
        if (isCancelled()) future.cancel(true);
    }
    void check() { if (isCancelled()) throw new CancellationException("[abto] Request cancelled."); }
}
