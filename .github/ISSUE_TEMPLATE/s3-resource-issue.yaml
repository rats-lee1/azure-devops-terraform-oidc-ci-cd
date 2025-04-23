name: Resource Request - s3
description: Resource Request - s3
title: '[Resource Request - s3]: '
labels: ['resource', 's3']
assignees:
  - xhoto
body:
  - type: markdown
    attributes:
      value: |
        # Create bucket
        Buckets are containers for data stored in S3. [Learn more](https://docs.aws.amazon.com/console/s3/usings3bucket)
  - type: input
    id: bucketName
    attributes:
      label: Bucket name
      description: Bucket name must be unique within the global namespace and follow the bucket naming rules.
      placeholder: ex. mybucket
    validations:
      required: false
  - type: dropdown
    id: account
    attributes:
      label: AWS Account (environment)
      description: Which account should the created resource be deployed into?
      options:
        - 029033808317 (dev)
        - 029033808318 (pr)
        - 029033808319 (stg)
        - 029033808320 (qa)
        - 029033808321 (prd)
    validations:
      required: true
  - type: textarea
    id: purpose
    attributes:
      label: Purpose of resource
      description: What is this resource used for?
      value: 'ex. s3 bucket for saving dumpfiles'
    validations:
      required: true
  - type: checkboxes
    id: terms
    attributes:
      label: Resource deployment agreement
      description: By submitting this form, you agree to follow our [guide](https://example.com)
      options:
        - label: I agree to follow this project's guide
          required: true
