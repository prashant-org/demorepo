"""Add description to SearchTemplate

Revision ID: 64c00337b9d1
Revises: 6e69f2cfcac1
Create Date: 2020-03-18 19:26:27.244125

"""
# This code is auto generated. Ignore linter errors.
# pylint: skip-file

# revision identifiers, used by Alembic.
revision = "64c00337b9d1"
down_revision = "6e69f2cfcac1"

from alembic import op
import sqlalchemy as sa


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column(
        "searchtemplate", sa.Column("description", sa.UnicodeText(), nullable=True)
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column("searchtemplate", "description")
    # ### end Alembic commands ###
