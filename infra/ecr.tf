#--------------------------------------------------------------
# ECR
#--------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name         = "ecr-fargate-cicd"
  force_delete = true
  # リポジトリのタグの変更可能性の設定
  image_tag_mutability = "MUTABLE"
  tags                 = merge(var.tags, { "Name" = "ecr-fargate-cicd" })
}

# NOTE: 同じECRリポジトリで使用できるaws_ecr_lifecycle_policyリソースは1つだけです。複数のルールを適用するには、ポリシーJSONで組み合わせる必要があります。
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy = jsonencode({
    rules = [
      {
        # NOTE: AWS ECR APIはrulePriorityに基づいてルールを並び替えるようです。TerraformのコードでrulePriorityの昇順でソートされていないルールを複数定義した場合、リソースはterraformのプランごとに再作成のフラグが立ってしまう。
        rulePriority = 1,
        description  = "keep last 10 images"
        # NOTE: アクション・タイプを指定する。サポートされている値はexpireです。
        action = {
          type = "expire"
        }
        selection = {
          tagStatus = "any" # タグが付いている or ついていない or どちらでも を指定
          # countType を sinceImagePushed に設定した場合は、countUnit と countNumber も指定して、リポジトリに存在するイメージの時間制限を指定します。
          countType = "imageCountMoreThan"
          countNumber = 10
        },
      },
    ],
  })
}
