"""Add admin bit to the User model

Revision ID: c380f6dff0bd
Revises: 58754b577173
Create Date: 2020-07-09 13:56:46.749168

"""
# This code is auto generated. Ignore linter errors.
# pylint: skip-file

# revision identifiers, used by Alembic.
revision = "c380f6dff0bd"
down_revision = "58754b577173"

from alembic import op
import sqlalchemy as sa


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column("user", sa.Column("admin", sa.Boolean(), nullable=True))
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column("user", "admin")
    # ### end Alembic commands ###