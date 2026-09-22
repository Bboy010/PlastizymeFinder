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

    /**
     * Render the --help text from nextflow_schema.json, so the help and the
     * schema can never drift apart.
     * @param schemaFile Path to nextflow_schema.json
     * @param manifest   The workflow manifest
     * @return The formatted help text
     */
    static String help(schemaFile, manifest) {
        def schema = new groovy.json.JsonSlurper().parse(new File(schemaFile.toString()))
        def groups = schema.definitions ?: [:]
        def lines = []

        lines << ''
        lines << "${manifest.name} ${manifest.version}"
        lines << "${manifest.description}"
        lines << ''
        lines << 'Usage:'
        lines << "  nextflow run ${manifest.name} -profile docker \\"
        lines << '      --input samplesheet.csv --pet_db pet_db.fasta --outdir results'

        groups.each { groupKey, group ->
            def props = group.properties
            if (!props) {
                return
            }
            def visible = props.findAll { propName, spec -> !spec.hidden }
            if (!visible) {
                return
            }
            lines << ''
            lines << (group.title ?: groupKey)
            visible.each { propName, spec ->
                def bits = []
                if (spec.description) {
                    bits << spec.description
                }
                if (spec.enum) {
                    bits << '(' + spec.enum.join('|') + ')'
                }
                if (spec['default'] != null) {
                    bits << '[' + spec['default'] + ']'
                }
                lines << String.format('  --%-22s %s', propName, bits.join(' '))
            }
        }

        lines << ''
        lines << 'Profiles: docker, singularity, conda, gpu, test, test_all'
        lines << "Docs: ${manifest.homePage}"
        lines << ''
        return lines.join(System.lineSeparator())
    }
}
