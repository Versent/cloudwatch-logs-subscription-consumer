set -eu -o pipefail

aws_assume_role() {
    # assume the role
    AWS_ROLE=( $(aws sts assume-role --role-arn "$1" --role-session-name "$2" --output text --query "Credentials.[SecretAccessKey,SessionToken,AccessKeyId]") )

    if [ -z "${AWS_ROLE+x}" ]; then
        echo false
        return 1
    fi

    cat <<EOF
export AWS_SECRET_ACCESS_KEY=${AWS_ROLE[0]}
export AWS_SESSION_TOKEN=${AWS_ROLE[1]}
export AWS_SECURITY_TOKEN=${AWS_ROLE[1]}
export EC2_SECURITY_TOKEN=${AWS_ROLE[1]}
export AWS_ACCESS_KEY_ID=${AWS_ROLE[2]}
EOF
}

launch_stack() {
    stackname="$1"
    template="$2"
    shift 2

    params=
    if [[ "$template" == https://s3.amazonaws.com/* ]]; then
        params+=( --template-url "$template" )
    else
        params+=( --template-body "$template" )
    fi

    echo Validating stack template
    aws cloudformation validate-template "${params[@]}" >/dev/null

    echo Checking for existing stack "$stackname"
    if ! aws cloudformation describe-stacks --stack-name "$stackname" --query 'Stacks[].StackId' --output text; then
        if [ "${DRYRUN:-}" = yes ]; then
            echo
            echo A new stack will be created
            return
        fi

        action=create
        params+=( "--on-failure=DO_NOTHING" )
        [ -n "${CFN_CREATE_ARGS+x}" ] && params+=( "${CFN_CREATE_ARGS[@]}" )
        echo Creating new stack "$stackname"

    elif [ "${DRYRUN:-}" = yes ]; then
        change_arn="$(aws cloudformation create-change-set "${params[@]}" --stack-name "$stackname" --change-set-name "${stackname}-change-set" --query "Id" --output text "$@")"
        while aws cloudformation describe-change-set --change-set-name "$change_arn" --query 'Status' --output text | grep -xFq $'CREATE_IN_PROGRESS\nCREATE_PENDING'; do
            sleep 1
        done

        echo
        echo Change set:
        aws cloudformation describe-change-set --change-set-name "$change_arn"
        aws cloudformation delete-change-set --change-set-name "$change_arn"
        return

    elif [ "${UPDATE:-}" = yes ]; then
        action=update
        [ -n "${CFN_UPDATE_ARGS+x}" ] && params+=( "${CFN_UPDATE_ARGS[@]}" )
        echo Updating stack "$stackname"

    else
        echo Refusing to update stack: '$UPDATE' is not set to yes >&2
        return 1
    fi

    [ -n "${CFN_STACK_ARGS+x}" ] && params+=( "${CFN_STACK_ARGS[@]}" )
    if error="$(aws cloudformation "${action}-stack" "${params[@]}" --stack-name "$stackname" "$@" 3>&2 2>&1 1>&3)"; then
      true
    else
      exit_code="$?"
      if [[ "$error" == *' No updates are to be performed.' ]]; then
        exit_code=0
        echo No updates are to be performed
      else
        echo "$error" >&2
      fi
      return "$exit_code"
    fi

    echo Waiting for stack "$action" to complete
    if ! aws cloudformation wait "stack-${action}-complete" --stack-name "$stackname"; then
        echo Stack "$action" failed
        aws cloudformation describe-stack-events --stack-name "$stackname" --query 'StackEvents[].[Timestamp,EventId,ResourceStatusReason]' --output text | grep -i -B999 -m1 'user initiated' | tac | grep -i fail
        return 1
    fi

    aws cloudformation describe-stacks --stack-name "$stackname" --query 'Stacks[].Outputs' --output table
    echo Stack "$action" complete
}

echo Performing config and discovery
export "$@" >/dev/null
[ -n "${envfile:-}" ] && source "$envfile"
export "$@" >/dev/null
