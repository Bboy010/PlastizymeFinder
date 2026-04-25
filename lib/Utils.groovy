class Utils {
    
    /**
     * Cap resource values to configured maximum limits
     * @param obj The resource value to check
     * @param type The resource type ('memory', 'time', or 'cpus')
     * @param params The params object containing max_* values
     * @return The capped resource value
     */
    static check_max(obj, type, params) {
        if (type == 'memory') {
            try {
                if (obj.compareTo(params.max_memory as nextflow.util.MemoryUnit) == 1) {
                    return params.max_memory as nextflow.util.MemoryUnit
                } else {
                    return obj
                }
            } catch (all) { 
                return obj 
            }
        } else if (type == 'time') {
            try {
                if (obj.compareTo(params.max_time as nextflow.util.Duration) == 1) {
                    return params.max_time as nextflow.util.Duration
                } else {
                    return obj
                }
            } catch (all) { 
                return obj 
            }
        } else if (type == 'cpus') {
            try {
                return Math.min(obj, params.max_cpus as int)
            } catch (all) { 
                return obj 
            }
        }
    }
}
