package au.org.ala.biocache.hubs

import com.google.common.base.Stopwatch
import groovy.util.logging.Slf4j

@Slf4j
class TimingUtils {

    static <V> V time(String message, Closure<V> body) {
        def sw = Stopwatch.createStarted()
        def r = body()
        log.debug("Timing - {}: {}", message, sw)
        return r
    }
}
