# Rodando este repositório no AWS Academy Learner Lab

Este guia é pra quando você tiver acesso de novo ao Learner Lab. Escrito passo a passo porque o Academy tem particularidades que não existem numa conta AWS normal.

## 1. Iniciar a sessão do Lab

1. Entre no AWS Academy → seu curso → **Learner Lab**.
2. Clique em **Start Lab** e espere o círculo ao lado de "AWS" ficar verde (leva ~1-2 min).
3. Clique em **AWS Details**. Vai aparecer um bloco `AWS CLI` com três valores:
   ```
   aws_access_key_id=...
   aws_secret_access_key=...
   aws_session_token=...
   ```
   Copie esse bloco inteiro.

## 2. Configurar as credenciais localmente

Cole o conteúdo copiado em `~/.aws/credentials`, dentro de um profile (pode chamar de `academy`):

```ini
[academy]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

Depois, antes de rodar qualquer comando `terraform`/`aws`:

```bash
export AWS_PROFILE=academy
```

**Importante:** essas credenciais expiram em poucas horas. Se o `terraform plan` começar a dar erro de `ExpiredToken` ou `InvalidClientTokenId`, volta no passo 1, pega um bloco novo e substitui no `~/.aws/credentials`.

## 3. Descobrir o ARN da LabRole

No Academy só existe uma role IAM pronta — a `LabRole` — e você não consegue criar outras. Pra pegar o ARN dela:

```bash
aws iam get-role --role-name LabRole --query 'Role.Arn' --output text
```

Vai devolver algo como `arn:aws:iam::123456789012:role/LabRole`. Guarde esse valor — ele vai no `lab_role_arn` do `terraform.tfvars`.

## 4. Criar o bucket do backend remoto (uma vez só, manualmente)

O `terraform init` com backend S3 exige que o bucket já exista antes — ele não cria pra você. Faça isso uma única vez (pelo console ou CLI):

```bash
aws s3 mb s3://SEU-NOME-UNICO-DE-BUCKET --region us-east-1

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Se o Lab reiniciar do zero numa próxima sessão de curso (pergunte ao professor se os recursos persistem entre sessões — geralmente persistem até a data final do lab, mas vale confirmar), talvez precise recriar esse bucket.

## 5. Preencher o terraform.tfvars

```hcl
aws_region   = "us-east-1"
project_name = "techchallenge"
lab_role_arn = "arn:aws:iam::123456789012:role/LabRole"  # o que você pegou no passo 3
```

## 6. Init, plan, apply

```bash
terraform init \
  -backend-config="bucket=SEU-NOME-UNICO-DE-BUCKET" \
  -backend-config="key=infra-kubernetes/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks"

terraform plan
terraform apply
```

## O que muda em relação a uma conta AWS normal

| Item | Conta normal | AWS Academy |
|---|---|---|
| Role do cluster EKS | Terraform cria uma nova | Reusa a `LabRole` existente (`create_iam_role = false`) |
| Role dos nodes | Terraform cria uma nova | Reusa a `LabRole` (mesmo ARN) |
| IRSA (IAM por Service Account) | Disponível | Desligado (`enable_irsa = false`) — exigiria criar um OIDC provider, que o Academy bloqueia |
| Criptografia de secrets do cluster (KMS) | Terraform cria uma KMS key | Desligado (`create_kms_key = false`) |
| CI/CD via OIDC (GitHub Actions assume role sem secret fixo) | Funciona | Não dá pra configurar (exige criar IAM role/provider próprios) — por enquanto, `terraform apply` roda manual ou via self-hosted runner com credenciais coladas a cada sessão |
| Região | Qualquer uma | Só `us-east-1` (ou `us-west-2`) |

## Pegadinhas conhecidas

- Se der erro `AccessDenied` em qualquer `iam:CreateRole`, `iam:CreatePolicy` ou `iam:CreateOpenIDConnectProvider`, é sinal de que algum recurso ainda está tentando criar IAM em vez de reusar a `LabRole` — provavelmente um addon do EKS ou uma dependência do módulo que ainda não desligamos.
- `terraform destroy` no fim de cada sessão de estudo evita gastar o crédito do Lab à toa (o Academy te dá um crédito limitado, ex.: $100).
