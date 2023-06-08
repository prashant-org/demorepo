"""Add ACL relationships

Revision ID: be32626451fb
Revises: None
Create Date: 2016-03-21 11:59:44.094720

Auto generated code by flask-migrate and Alembic.
"""
# This code is auto generated. Ignore linter errors.
# pylint: skip-file

# revision identifiers, used by Alembic.
revision = "be32626451fb"
down_revision = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.add_column(
        "searchindex_accesscontrolentry",
        sa.Column("group_id", sa.Integer(), nullable=True),
    )
    op.create_foreign_key(
        None, "searchindex_accesscontrolentry", "group", ["group_id"], ["id"]
    )
    op.add_column(
        "sketch_accesscontrolentry", sa.Column("group_id", sa.Integer(), nullable=True)
    )
    op.create_foreign_key(
        None, "sketch_accesscontrolentry", "group", ["group_id"], ["id"]
    )
    op.add_column(
        "view_accesscontrolentry", sa.Column("group_id", sa.Integer(), nullable=True)
    )
    op.create_foreign_key(
        None, "view_accesscontrolentry", "group", ["group_id"], ["id"]
    )
    ### end Alembic commands ###


def downgrade():
    ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint(None, "view_accesscontrolentry", type_="foreignkey")
    op.drop_column("view_accesscontrolentry", "group_id")
    op.drop_constraint(None, "sketch_accesscontrolentry", type_="foreignkey")
    op.drop_column("sketch_accesscontrolentry", "group_id")
    op.drop_constraint(None, "searchindex_accesscontrolentry", type_="foreignkey")
    op.drop_column("searchindex_accesscontrolentry", "group_id")
    ### end Alembic commands ###
