odpsample: {
	annotations: {}
	attributes: workload: definition: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
	}
	description: "My Sample ODP Appl Type"
	labels: {}
	type: "component"
}

template: {
	output: {
		spec: {
			selector: matchLabels: "app.oam.dev/component": parameter.name
			template: {
				metadata: labels: "app.oam.dev/component": parameter.name
				spec: containers: [{
					name:  parameter.name
					image: parameter.image
				}]
			}
		}
		apiVersion: "apps/v1"
		kind:       "Deployment"
	}
	parameter: {
		name: string
		image: string
	}
}
